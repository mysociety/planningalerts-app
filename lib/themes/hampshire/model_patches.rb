Rails.configuration.to_prepare do
  Application.class_eval do
    define_index do
      indexes description
      indexes address
      indexes suburb, :facet => true
      indexes postcode
      indexes authority(:full_name), :as => :authority, :facet => true
      has date_scraped
    end
  end
end