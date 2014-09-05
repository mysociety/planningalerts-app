namespace :planningalerts do
  namespace :applications do
    desc "Scrape new applications, index them, send emails and generate XML sitemap"
    task :scrape_and_email => [:scrape, 'ts:in', :email, :sitemap]

    desc "Scrape all the applications for the last few days for all the loaded authorities"
    task :scrape, [:authority_short_name] => :environment do |t, args|
      authorities = args[:authority_short_name] ? [Authority.find_by_short_name_encoded(args[:authority_short_name])] : Authority.active
      Application.collect_applications(authorities, Logger.new(STDOUT))
    end

    desc "Send planning alerts"
    task :email => :environment do
      Alert.process_all_active_alerts(Logger.new(STDOUT))
    end

    desc "Load planning applications from a CSV, index them, generate XML sitemap"
    task :load_from_csv_and_index, [:authority_id, :filename] => [:load_from_csv, 'ts:in', :sitemap]

    desc "Load planning applications from a CSV"
    task :load_from_csv, [:authority_id, :filename] => :environment do |t, args|
      require 'global_convert'
      # TODO - probably load one file for all authorities in the future
      authority = Authority.find(args[:authority_id])
      puts "Loading planning applications for #{authority.full_name_and_state}"
      file = File.read(args[:filename])
      csv = CSV.parse(file, :headers => true)
      csv.each do |row|
        attributes = {
          :council_reference => row["application_number"],
          :authority_id => authority.id,
          :address => row["location"],
          :description => row["proposal"],
          :date_received => row["recieved_date"],
          :date_scraped => Time.now, # Can't be nil
          # Can't be nil because has to validate as a URL - TODO fix this
          :info_url => 'http://example.com'
          # TODO
          # category
          # decision date
          # decision method (commitee, appeal, etc)
          # breaking the address down into smaller parts (geocoder?), suburb, postcode especially
          # for/against counts
          # outcome
        }
        if row["gridref_east"] and row["gridref_north"]
          # Get a location in lat/ln from the OSGB coords in the CSV
          location = GlobalConvert::Location.new(
            input: {
              projection: :osgb36,
              lon: row["gridref_east"].to_f,
              lat: row["gridref_north"].to_f
            },
            output: {
              projection: :wgs84
            }
          )
          attributes.merge({
            :lat => location.lat,
            :lng => location.lon
          })
        end
        application = Application.where(attributes).first_or_initialize
        application.save!
      end
    end

    desc "Load planning applications from a PublishMyData dataset, index them generate XML sitemap"
    task :load_from_publishmydata_and_index, [:authority_id, :dataset] => [:load_from_publishmydata, 'ts:in', :sitemap]

    desc "Load planning applications from a PublishMyData dataset"
    task :load_from_publishmydata, [:authority_id, :dataset] => :environment do |t, args|
      data_access = YAML.load_file("#{Rails.root}/config/publishmydata.yml")

      require 'rest-client'
      require 'json'
      require 'global_convert'

      resources_url = 'http://hantshub-planning.publishmydata.com/resources.json'
      resource_url = 'http://hantshub-planning.publishmydata.com/resource.json'
      page = 1
      per_page = 11
      applications = []
      done = false

      authority = Authority.find(args[:authority_id])

      while !done
        request = RestClient::Request.new(
          :method => :get,
          :url => resources_url,
          :headers => {
            :params => {
              :page => page,
              :per_page => per_page,
              :dataset => args[:dataset],
              :type_uri => 'http://data.hampshirehub.net/def/planning/PlanningApplication'
            }
          },
          :user => data_access[:username],
          :password => data_access[:password],
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
          puts "No more data"
          done = true
        end
      end

      # Wrap this in one big transation to make it slightly faster
      # https://www.coffeepowered.net/2009/01/23/mass-inserting-data-in-rails-without-killing-your-performance/
      ActiveRecord::Base.transaction do
        applications.each do |application|
          # Parse the date received
          date_received = application['http://data.hampshirehub.net/def/planning/dateReceived'][0]['@value']
          date_received = Time.iso8601(date_received)

          # Pull in the localisation record
          place_json = RestClient::Request.new(
            :method => :get,
            :url => resource_url,
            :headers => {
              :params => {
                  :uri => application['http://schema.org/location'][0]['@id']
              },
            },
            :user => data_access[:username],
            :password => data_access[:password],
          ).execute
          # the "resource" endpoint returns an array despite not being plural
          place = JSON.parse(place_json)[0]
          # Some places, e.g http://data.hampshirehub.net/id/planning-application/district-council/rushmoor/14/00311/CONDPP/location
          # don't have easting/northings
          if place['http://data.ordnancesurvey.co.uk/ontology/spatialrelations/easting'] \
             and place['http://data.ordnancesurvey.co.uk/ontology/spatialrelations/northing']
            location = GlobalConvert::Location.new(
              input: {
                projection: :osgb36,
                lon: place['http://data.ordnancesurvey.co.uk/ontology/spatialrelations/easting'][0]['@value'],
                lat: place['http://data.ordnancesurvey.co.uk/ontology/spatialrelations/northing'][0]['@value']
              },
              output: {
                projection: :wgs84
              }
            )
          end

          # Build basic attributes
          attributes = {
            :council_reference => application['http://data.hampshirehub.net/def/planning/hasCaseReference'][0]['@value'],
            :authority_id => authority.id,
            :description => application['http://data.hampshirehub.net/def/planning/hasCaseText'][0]['@value'],
            :address => place['http://www.w3.org/2000/01/rdf-schema#label'][0]['@value'],
            :info_url => application['http://xmlns.com/foaf/page'][0]['@id'],
            :date_received => date_received,
            :date_scraped => Date.today.to_s,
          }

          if location
            attributes.merge({:lat => location.lat, :lng => location.lon})
          end

          unless Application.find_by_council_reference attributes[:council_reference]
            application = Application.new attributes
            application.save!
          end
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

    desc "Classify planning applications"
    task :classify_csv, [:filename] => :environment do |t, args|
      classifier = ApplicationClassifier.new('applications')
      file = File.read(args[:filename])
      csv = CSV.parse(file, :headers => true)
      correct = 0
      incorrect = 0
      csv.each do |row|
        description = row["description"]
        category = classifier.classify(description)
        row_category = row["category"]
        if row_category.blank?
          puts "Classified previously unknown: #{description} as: #{category}"
        elsif category.blank?
          puts "No categorisation possible for: #{description}"
        else
          if category == row["category"]
            puts "Correctly Classified: #{description} as: #{category} when it was actually #{row_category}"
            correct += 1
          else
            puts "Incorrectly Classified: #{description} as: #{category} when it was actually #{row_category}"
            incorrect += 1
          end
        end
      end
      puts '============================='
      puts "Total rows: #{csv.length}"
      puts "Total correct: #{correct}"
      puts "Total incorrect: #{incorrect}"
      score = (correct.to_f / csv.length.to_f) * 100
      puts "Score: #{score}%"
    end
  end

  desc "Generate XML sitemap"
  task :sitemap => :environment do
    s = PlanningAlertsSitemap.new
    s.generate
  end

  # A response to something bad
  namespace :emergency do
    # TODO: Move comments of destroyed applications to the redirected application
    desc "Applications for an authority shouldn't have duplicate values of council_reference and so this removes duplicates."
    task :fix_duplicate_council_references => :environment do
      # First find all duplicates
      duplicates = Application.group(:authority_id).group(:council_reference).count.select{|k,v| v > 1}.map{|k,v| k}
      duplicates.each do |authority_id, council_reference|
        authority = Authority.find(authority_id)
        puts "Removing duplicates for #{authority.full_name_and_state} - #{council_reference} and redirecting..."
        applications = authority.applications.find_all_by_council_reference(council_reference)
        # The first result is the most recently scraped. We want to keep the last result which was the first
        # one scraped
        application_to_keep = applications[-1]
        applications[0..-2].each do |a|
          ActiveRecord::Base.transaction do
            # Set up a redirect from the wrong to the right
            ApplicationRedirect.create!(:application_id => a.id, :redirect_application_id => application_to_keep.id)
            a.destroy
          end
        end
      end
    end
  end
end
