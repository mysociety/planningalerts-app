Rails.configuration.to_prepare do
  Application.class_eval do
    define_index do
      indexes description
      indexes address
      indexes suburb
      indexes postcode
      indexes authority(:full_name), :as => :authority, :facet => true

      # to be added when available
      indexes category, :facet => true
      indexes status, :facet => true

      # enable geosearch - see http://pat.github.io/thinking-sphinx/geosearching.html
      has 'RADIANS("applications"."lat")', :as => :latitude,  :type => :float
      has 'RADIANS("applications"."lng")', :as => :longitude, :type => :float

      # Postgres-specific bit:
      group_by '"applications"."lat"', '"applications"."lng"'

      has date_scraped
    end

    validates :category, :inclusion => {
        :in => Configuration::THEME_HAMPSHIRE_CATEGORIES,
        :allow_nil => true,
        :message => "%{value} is not an allowed category"
      }

    def geocode
      # Override geocode with a noop because we don't need to geocode
      # applications
    end

    def as_json(options={})
      result = super(options)
      result['application'].merge!({
        'authority' => {
          'short_name_encoded' => authority.short_name_encoded
        }
      })
      result
    end
  end

  Authority.class_eval do
    def applications_received_per_week
      # warning - assumes postgres!
      h = applications.group("date_scraped - interval '1 day' * EXTRACT(DOW FROM date_received)").count
      h.sort
    end

    def median_applications_received_per_week
      v = applications_received_per_week.select{|a| a[1] > 0}.map{|a| a[1]}.sort
      v[v.count / 2]
    end

    def percentage_approved
      (applications.where(:status => "Approved").count.to_f / applications.count.to_f * 100).round

    end

    def percentage_delayed
      (applications.where(:delayed => true).count.to_f / applications.count.to_f * 100).round
    end
  end

  Location.class_eval do
    def self.geocode(address)
      # Bias towards a specific bounding box
      boundsSW = GeoKit::LatLng.new(Configuration::THEME_HAMPSHIRE_BOUNDING_BOX_SW[0],
                                    Configuration::THEME_HAMPSHIRE_BOUNDING_BOX_SW[1])
      boundsNE = GeoKit::LatLng.new(Configuration::THEME_HAMPSHIRE_BOUNDING_BOX_NE[0],
                                    Configuration::THEME_HAMPSHIRE_BOUNDING_BOX_NE[1])
      bounds = GeoKit::Bounds.new(boundsSW, boundsNE)
      r = Geokit::Geocoders::GoogleGeocoder3.geocode(address, :bias => bounds)
      r = r.all.find{|l| Location.new(l).in_correct_country?} || r
      l = Location.new(r)
      l.original_address = address
      l
    end
  end
end