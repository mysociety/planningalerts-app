load File.expand_path('../controller_base.rb',  __FILE__)

class HampshireTheme
  class ApplicationsController < ControllerBase
    load "validate.rb"

    def address
      if params[:location]
        if MySociety::Validate.is_valid_postcode(params[:location])
          postcode = CGI::escape(params[:location].gsub(" ", ""))
          url = "#{MySociety::Config::get('MAPIT_URL')}/postcode/#{postcode}"
          begin
            result = HTTParty.get(url)
            content = result.body
            data = JSON.parse(content)
            lat = data["wgs84_lat"]
            lng = data["wgs84_lon"]
            if !lat.blank? and !lng.blank?
              redirect_to search_applications_path({:lat => lat, :lng => lng, :postcode => params[:location], :search => params[:search]})
            else
              @error = "Postcode is not valid"
            end
          rescue SocketError, Errno::ETIMEDOUT, JSON::ParserError
            @error = "Postcode is not valid"
          end
        else
          address = CGI::escape(params[:location])
          r = Location.geocode(address)
          if r.success
            redirect_to search_applications_path({:lat => r.lat, :lng => r.lng, :address => address, :search => params[:search]})
          else
            @error = "Address not found"
          end
        end
      end
      # return false to signal to the filter method to halt execution
      # before processing the original controller method
      return false
    end

    def search
      @distance_in_miles = 5
      @search = params[:search]
      # "anything" is our special keyword meaning don't do a full text search
      if !@search.blank? && @search.strip.downcase == "anything"
        @search = ''
      end
      @lat = params[:lat]
      @lng = params[:lng]
      if @lat and @lng
        url = "#{MySociety::Config::get('MAPIT_URL')}/point/4326/#{@lng},#{@lat}"
        begin
          result = HTTParty.get(url)
          content = result.body
          data = JSON.parse(content)
          @authorities = find_planning_authorities(data)
        rescue SocketError, Errno::ETIMEDOUT, JSON::ParserError
          # TBD
        end

        if @search.blank?
          # defaults to miles
          # can change to km by appending :units => :km to args
          @applications = Application.near([@lat, @lng], @distance_in_miles)
        else
          @search_lat = @lat.to_f / 180 * Math::PI
          @search_lng = @lng.to_f / 180 * Math::PI
          @search_range = @distance_in_miles * 1.609344
          @applications = do_search(true)
          @rss = search_applications_path(:format => "rss", :search => @search, :page => nil)
        end
      else
        unless @search.blank?
          @applications = do_search
          @rss = search_applications_path(:format => "rss", :search => @search, :page => nil)
        end
      end
      return false
    end

    protected

    def do_search(use_distance=false)
      search_params = {:per_page => 10,
                       :order => {:date_scraped => :desc},
                       :page => params[:page]}
      with_params = {}
      if params[:authority] and !use_distance
        authority_facet = Zlib.crc32(CGI::unescape(params[:authority]))
        with_params[:authority_facet] = authority_facet
      end
      if use_distance
        search_params[:geo] = [@search_lat, @search_lng]
        with_params['@geodist'] = 0.0..@search_range
      end
      # uncomment once we've got categories wired up
      # if params[:category]
      #   with_params[:category_facet] = Zlib.crc32(params[:category])
      # end
      #
      # uncomment once we've got status wired up
      # if params[:status]
      #   with_params[:status_facet] = Zlib.crc32(params[:status])
      # end
      unless with_params.empty?
        search_params[:with] = with_params
      end
      Application.search @search, search_params
    end

    def find_planning_authorities(data)
      return [] if data.blank?
      result = []
      district_council = data.select { |key, value| value.is_a?(Hash) and value["type"] == "DIS" }
      if !district_council.blank?
        result << {
          :id => district_council.keys.first,
          :name => district_council.values.first["name"],
          :type => "DIS"
        }
      end
      county_council = data.select { |key, value| value.is_a?(Hash) and value["type"] == "CTY" }
      if !county_council.blank?
        result << {
          :id => county_council.keys.first,
          :name => county_council.values.first["name"],
          :type => "CTY"
        }
      end
      unitary_authority = data.select { |key, value| value.is_a?(Hash) and value["type"] == "UTA" }
      if !unitary_authority.blank?
        result << {
          :id => unitary_authority.keys.first,
          :name => unitary_authority.values.first["name"],
          :type => "UTA"
        }
      end
      national_park_authority = data.select { |key, value| value.is_a?(Hash) and value["type"] == "NPA" }
      if !national_park_authority.blank?
        result << {
          :id => national_park_authority.keys.first,
          :name => national_park_authority.values.first["name"],
          :type => "NPA"
        }
      end

      result
    end
  end
end