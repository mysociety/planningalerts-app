namespace :hampshire do
  desc "Calculate authority-wide stats based on currently loaded data"
  task :calculate_authority_stats => :environment do
    # get a list of all the categories
    categories = Configuration::THEME_HAMPSHIRE_CATEGORIES

    # Wrap this in one big transaction to make it slightly faster
    # https://www.coffeepowered.net/2009/01/23/mass-inserting-data-in-rails-without-killing-your-performance/
    app_statuses = Configuration::THEME_HAMPSHIRE_STATUSES
    ActiveRecord::Base.transaction do
      Authority.enabled.each do |authority|
        attributes = {
          :authority_id => authority.id,
          :category => nil,
          :total => authority.applications.count,
          :delayed => authority.applications.where(:delayed => true).count,
          :approved => authority.applications.where(:status => app_statuses['approved']).count,
          :refused => authority.applications.where(:status => app_statuses['refused']).count,
          :in_progress => authority.applications.where(:status => app_statuses['in_progress']).count,
        }

        stats = AuthorityStatsSummary.where(
          :authority_id => authority.id,
          :category => nil
        ).first_or_initialize(attributes)
        unless stats.new_record?
          stats.update_attributes(attributes)
        end
        stats.save!

        categories.each do |category|
          attributes = {
            :authority_id => authority.id,
            :category => category,
            :total => authority.applications.where(:category => category).count,
            :delayed => authority.applications.where(:category => category, :delayed => true).count,
            :approved => authority.applications.where(:category => category, :status => app_statuses['approved']).count,
            :refused => authority.applications.where(:category => category, :status => app_statuses['refused']).count,
            :in_progress => authority.applications.where(:category => category, :status => app_statuses['in_progress']).count,
          }
          stats = AuthorityStatsSummary.where(
            :authority_id => authority.id,
            :category => category
          ).first_or_initialize(attributes)
          unless stats.new_record?
            stats.update_attributes(attributes)
          end
          stats.save!
        end
      end
    end
  end

  namespace :applications do
    desc "Load planning applications from a PublishMyData dataset, index them generate XML sitemap"
    task :load_from_publishmydata_and_index, [:authority_id, :dataset] => [:load_from_publishmydata, 'ts:in', 'planningalerts:sitemap']

    desc "Load planning applications from a PublishMyData dataset"
    task :load_from_publishmydata, [:authority_id, :dataset] => :environment do |t, args|
      require 'rest-client'
      require 'json'
      require 'global_convert'

      page = 1
      per_page = 100
      applications = []
      done = false

      authority = Authority.find(args[:authority_id])

      classifier = ApplicationClassifier.new('applications')

      while !done
        request = RestClient::Request.new(
          :method => :get,
          :url => 'http://hantshub-planning.publishmydata.com/resources.json',
          :headers => {
            :params => {
              :page => page,
              :per_page => per_page,
              :dataset => args[:dataset],
              :type_uri => 'http://data.hampshirehub.net/def/planning/PlanningApplication'
            }
          },
          :user => Configuration::PUBLISHMYDATA_USER,
          :password => Configuration::PUBLISHMYDATA_PASSWORD,
        )
        response = request.execute

        puts "Requesting page: #{request.url}"

        page_applications = JSON.parse(response)

        if page_applications.length > 0
          applications.push(*page_applications)
          # If this was a full page, check for more
          if page_applications.length == per_page
            page += 1
          else
            puts "No more data"
            done = true
          end
        else
          puts "No data returned"
          done = true
        end
      end

      # Wrap this in one big transation to make it slightly faster
      # https://www.coffeepowered.net/2009/01/23/mass-inserting-data-in-rails-without-killing-your-performance/
      ActiveRecord::Base.transaction do
        applications.each do |application|
          target_date = nil
          delayed = nil

          # Parse the date received
          date_received = application['http://data.hampshirehub.net/def/planning/dateReceived'][0]['@value']
          date_received = Time.iso8601(date_received)
          # Extract data from associated records
          description = PMDApplicationProcessor.extract_description(application)
          place = PMDApplicationProcessor.extract_address(application)
          location = PMDApplicationProcessor.extract_location(place)
          decision = PMDApplicationProcessor.extract_decision(application)
          status = PMDApplicationProcessor.extract_status(decision)
          decision_date = PMDApplicationProcessor.extract_decision_date(decision, status)
          delayed = PMDApplicationProcessor.extract_delayed(application, decision, status, decision_date)
          council_category = PMDApplicationProcessor.extract_council_category(application)
          category = PMDApplicationProcessor.extract_category(council_category, description, classifier)

          # Build basic attributes
          attributes = {
            :council_reference => application['http://data.hampshirehub.net/def/planning/hasCaseReference'][0]['@value'],
            :authority_id => authority.id,
            :description => description,
            :address => place['http://www.w3.org/2000/01/rdf-schema#label'][0]['@value'],
            :info_url => application['http://xmlns.com/foaf/page'][0]['@id'],
            :date_received => date_received,
            :date_scraped => Date.today.to_s,
            :status => status,
            :decision_date => decision_date,
            :delayed => delayed,
            :council_category => council_category,
            :category => category
          }

          if location
            attributes.merge!({:lat => location[:lat], :lng => location[:lng]})
          end

          application = Application.where(
            :authority_id => authority.id,
            :council_reference => attributes[:council_reference]
          ).first_or_initialize(attributes)
          unless application.new_record?
            application.update_attributes(attributes)
          end
          application.save!
        end
      end
    end

    desc "Train the application classifier"
    task :train_classifier, [:filename, :limit] => :environment do |t, args|
      ApplicationClassifier.train_from_csv(
        args[:filename],
        args[:limit].to_i,
        'applications'
      )
    end

    desc "Test the application classifier"
    task :test_classifier, [:filename] => :environment do |t, args|
      classifier = ApplicationClassifier.new('applications')
      file = File.read(args[:filename])
      csv = CSV.parse(file, :headers => true)
      correct = 0
      incorrect = 0
      correct_reasons = []
      incorrect_reasons = []
      csv.each do |row|
        description = row["description"]
        category = classifier.classify(description)
        row_category = row["category"]
        row_category = nil if row_category.blank?
        if category == row_category
          correct_reasons.push("Correctly Classified: #{description} as: #{category.inspect}")
          correct += 1
        else
          incorrect_reasons.push("Incorrectly Classified: #{description} as: #{category.inspect} when it was actually #{row_category.inspect}")
          incorrect += 1
        end
      end
      correct_reasons.each { |reason| puts reason }
      puts '============================='
      incorrect_reasons.each { |reason| puts reason }
      puts '============================='
      puts "Total rows: #{csv.length}"
      puts "Total correct: #{correct}"
      puts "Total incorrect: #{incorrect}"
      score = (correct.to_f / csv.length.to_f) * 100
      puts "Score: #{score}%"
    end

    desc "Classify applications in the database"
    task :classify => :environment do
      classifier = ApplicationClassifier.new('applications')
      applications = Application.all
      # Wrap this in one big transation to make it slightly faster
      # https://www.coffeepowered.net/2009/01/23/mass-inserting-data-in-rails-without-killing-your-performance/
      ActiveRecord::Base.transaction do
        applications.each do |application|
          category = PMDApplicationProcessor.extract_category(application.council_category, application.description, classifier)
          application.category = category
          application.save!
        end
      end
    end
  end
end