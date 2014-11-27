class Theme
  def domain
    host.split(":").first
  end

  def email_from
    "#{app_name} <#{email_from_address}>"
  end
end

class DefaultTheme < Theme
  def theme
    "default"
  end

  def recognise?(request)

    true
  end

  def host
    ActionMailer::Base.default_url_options[:host]
  end

  def app_name
    Configuration::EMAIL_FROM_NAME
  end

  def email_from_address
    Configuration::EMAIL_FROM_ADDRESS
  end

  def google_analytics_key
    Configuration::GOOGLE_ANALYTICS_KEY
  end

  def google_maps_client_id
    Configuration::GOOGLE_MAPS_CLIENT_ID if defined?(Configuration::GOOGLE_MAPS_CLIENT_ID)
  end

# TODO Put this in the config
  def default_meta_description
    "A free service which searches Australian planning authority websites and emails you details of applications near you"
  end
end

class NSWTheme < Theme
  def theme
    "nsw"
  end

  def recognise?(request)
    tld = domain.split(".").count - 1
    request.domain(tld) == domain
  end

  # This might have a port number included
  def host
    Configuration::THEME_NSW_HOST
  end

  def app_name
    Configuration::THEME_NSW_EMAIL_FROM_NAME
  end

  def email_from_address
    Configuration::THEME_NSW_EMAIL_FROM_ADDRESS
  end

  def cuttlefish_user_name
    Configuration::THEME_NSW_CUTTLEFISH_USER_NAME
  end

  def cuttlefish_password
    Configuration::THEME_NSW_CUTTLEFISH_PASSWORD
  end

  def google_analytics_key
    Configuration::THEME_NSW_GOOGLE_ANALYTICS_KEY
  end

  def google_maps_client_id
    nil
  end

  # TODO Put this in the config
  def default_meta_description
    "Discover what's happening in your local area in NSW. Find out about new building work. Get alerted by email."
  end
end

class HampshireTheme < Theme
  def theme
    "hampshire"
  end

  def recognise?(request)
    tld = domain.split(".").count - 1
    request.domain(tld) == domain
  end

  # This might have a port number included
  def host
    if Configuration.const_defined?('THEME_HAMPSHIRE_HOST')
      Configuration::THEME_HAMPSHIRE_HOST
    else
      "not_in_use"
    end
  end

  def app_name
    if Configuration.const_defined?('THEME_HAMPSHIRE_EMAIL_FROM_NAME')
      Configuration::THEME_HAMPSHIRE_EMAIL_FROM_NAME
    else
      "not_in_use"
    end
  end

  def email_from_address
    if Configuration.const_defined?('THEME_HAMPSHIRE_EMAIL_FROM_ADDRESS')
      Configuration::THEME_HAMPSHIRE_EMAIL_FROM_ADDRESS
    else
      ""
    end
  end

  def cuttlefish_user_name
    Configuration::THEME_HAMPSHIRE_CUTTLEFISH_USER_NAME
  end

  def cuttlefish_password
    Configuration::THEME_HAMPSHIRE_CUTTLEFISH_PASSWORD
  end

  def google_analytics_key
    Configuration::THEME_HAMPSHIRE_GOOGLE_ANALYTICS_KEY
  end

  def google_maps_client_id
    nil
  end

  # TODO Put this in the config
  def default_meta_description
    "Browse and explore planning applications in Hampshire."
  end
end

class ThemeChooser
  THEMES = [NSWTheme.new, HampshireTheme.new, DefaultTheme.new]

  def self.create(theme)
    r = THEMES.find{|t| t.theme == theme}
    raise "Unknown theme #{theme}" if r.nil?
    r
  end

  def self.themer_from_request(request)
    if defined?(Configuration::THEME)
      theme = THEMES.find{|t| t.theme == Configuration::THEME}
      raise "Unknown theme #{theme}" if theme.nil?
      theme
    else
      THEMES.find{|t| t.recognise?(request)}
    end
  end
end
