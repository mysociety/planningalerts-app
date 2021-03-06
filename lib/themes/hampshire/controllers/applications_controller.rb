load File.expand_path('../controller_base.rb',  __FILE__)
require "#{Rails.root.to_s}/lib/themes/hampshire/models/hampshire_search.rb"

class HampshireTheme
  class ApplicationsController < ControllerBase
    $:.push(File.join(File.dirname(__FILE__), '../../commonlib/rblib'))
    require "validate.rb"
    require "mapit.rb"

    def search
      @categories = ::Configuration::THEME_HAMPSHIRE_CATEGORIES
      @categories_json = @categories.as_json

      # Whether we're showing the "results" view or the initial homepage view
      @show_results = params.has_key?(:results) or false

      if params[:location] or params[:search] or params[:authority]
        @search = HampshireSearch.new(:location => params[:location],
                                      :search => params[:search],
                                      :status => params[:status],
                                      :page => params[:page])
        if @search.valid?
          @show_results = true
          @map_display_possible = false
          @display = 'list'

          @applications = @search.perform_search
          @applications_json = @applications.to_json
          @authorities = @search.authorities
          if @authorities.count > 0
            @authority = Authority.find_by_mapit_id(@authorities.first[:id])
            unless @authority #hmm, that didn't work - try by name
              @authority = Authority.find_by_full_name(@authorities.first[:name])
            end
          end

          if @search.is_location_search?
            @map_display_possible = true
            if params['display'].blank? or params['display'] == 'map'
              @display = 'map'
            end
          end

          if @display == 'map' and @applications.total_pages > 1
            # Thinking sphinx limits you to 1,000 searches by default, so that's
            # the most we can get.
            # We might have a stray page param if we've switched to the map
            # from a list view, therefore we force the page param to 1
            @applications_json = @search.perform_search({:per_page => 1000, :page => 1}).to_json
          end

          # Build a url to allow us to return to this search later, so that we
          # can show return-to links on the application pages
          valid_params = params.slice(:location, :search, :status, :page, :results)
          @return_to_search_params = Hash[valid_params.map { |k, v| ["search_#{k}", v] }]
        end
      end
      return false
    end

    def show
      valid_params = params.slice(:search_location, :search_search, :search_status, :search_page, :search_results)
      return_to_search_params = Hash[valid_params.map { |k, v| ["#{k}".gsub('search_', ''), v] }]
      unless return_to_search_params.empty?
        url_params = {:controller => 'applications', :action => 'search', :only_path => true}.merge!(return_to_search_params)
        @return_to_search_url = url_for(url_params)
      end
      # Not returning false because we want the normal action to continue too
    end
  end
end