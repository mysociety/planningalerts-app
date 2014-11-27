load File.expand_path('../controller_base.rb',  __FILE__)
require "#{Rails.root.to_s}/lib/themes/hampshire/models/hampshire_search.rb"

class HampshireTheme
  class AuthoritiesController < ControllerBase
    def index
      @authorities = Authority.enabled
      return false
    end

    def show
      # Deal with posts to the authority selector
      if params[:full_name]
        authority = Authority.find_by_short_name_encoded!(params[:full_name])
        if authority
          redirect_to authority_url(authority.short_name_encoded)
        end
      end
      @return_to_search_params = {}
      @authorities = Authority.enabled
      @authority = Authority.find_by_short_name_encoded!(params[:id])
      @applications = @authority.applications.paginate(:page => params[:page], :per_page => 30, :order => "date_received DESC")
      return false
    end
  end
end