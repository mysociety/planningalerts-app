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
      indexes status, :facet => true

      # enable geosearch - see http://pat.github.io/thinking-sphinx/geosearching.html
      has 'RADIANS("applications"."lat")', :as => :latitude,  :type => :float
      has 'RADIANS("applications"."lng")', :as => :longitude, :type => :float

      # Postgres-specific bit:
      group_by '"applications"."lat"', '"applications"."lng"'

      has date_scraped
    end

    validates :category, :inclusion => {
        :in => [
          'Anything',
          'Conservatories',
          'Extensions',
          'Loft Conversions',
          'Garage Conversions',
          'Doors and Windows',
          'Fences, Gates and Garden Walls',
          'Outbuildings',
          'Trees and Hedges',
          'Major Developments'
        ],
        :allow_nil => true,
        :message => "%{value} is not an allowed category"
      }
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
end