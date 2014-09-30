Rails.configuration.to_prepare do
  Application.class_eval do
    define_index do
      indexes description
      indexes address
      has date_scraped
    end
  end
end