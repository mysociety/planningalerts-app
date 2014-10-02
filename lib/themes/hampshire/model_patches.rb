Rails.configuration.to_prepare do
  Application.class_eval do
    define_index do
      indexes description
      indexes address
      indexes suburb
      indexes postcode
      indexes authority(:full_name), :as => :authority, :facet => true

      # to be added when available
      # indexes category, :facet => true
      # indexes status, :facet = true

      # enable geosearch - see http://pat.github.io/thinking-sphinx/geosearching.html
      has 'RADIANS("applications"."lat")', :as => :latitude,  :type => :float
      has 'RADIANS("applications"."lng")', :as => :longitude, :type => :float

      # Postgres-specific bit:
      group_by '"applications"."lat"', '"applications"."lng"'

      has date_scraped
    end
  end
end