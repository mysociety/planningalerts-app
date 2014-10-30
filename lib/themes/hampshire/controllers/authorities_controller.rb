load File.expand_path('../controller_base.rb',  __FILE__)
require "#{Rails.root.to_s}/lib/themes/hampshire/models/hampshire_search.rb"

class HampshireTheme
  class AuthoritiesController < ControllerBase
    def index
      @authorities = Authority.enabled
      return false
    end
  end
end