require 'stuff-classifier'
require 'redis'

class ApplicationClassifier < Object
  # A thin wrapper around stuff-classifier's Bayes classifier, to handle
  # training from a specific csv and auto-loading the trained data

  def initialize(name)
    @name = name
    storage = StuffClassifier::RedisStorage.new(@name)
    @classifier = StuffClassifier::Bayes.new(@name, :storage => storage)
    puts "Initialised classifier"
    puts "Categories: #{@classifier.categories.inspect}"
  end

  def classify(description)
    return @classifier.classify(description)
  end

  def self.train_from_csv(csv_path, limit, name)
    storage = StuffClassifier::RedisStorage.new(name)
    classifier = StuffClassifier::Bayes.new(name, :storage => storage, :purge_state => true)
    training_file = File.read(csv_path)
    training_csv = CSV.parse(training_file, :headers => true)
    if limit == 0
      limit = training_csv.length
    end
    count = 0
    puts "Training from #{csv_path}, will limit to first #{limit} rows."
    training_csv.each do |row|
      if count <= limit
        category = row["category"]
        description = row["description"]
        puts "Training: #{description} as #{category}."
        classifier.train(category, description)
        count += 1
      else
        puts "Reached limit, skipping."
        break
      end
    end
    puts "Trained"
    classifier.save_state
  end
end
