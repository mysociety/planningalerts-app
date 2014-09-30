load File.expand_path('../controller_base.rb',  __FILE__)

class HampshireTheme
  class ApplicationsController < ControllerBase
    load "validate.rb"

    def address
      if params[:q]
        if MySociety::Validate.is_valid_postcode(params[:q])
          postcode = CGI::escape(params[:q].gsub(" ", ""))
          url = "#{MySociety::Config::get('MAPIT_URL')}/postcode/#{postcode}"
          begin
            result = HTTParty.get(url)
            content = result.body
            data = JSON.parse(content)
            lat = data["wgs84_lat"]
            lng = data["wgs84_lon"]
            if !lat.blank? and !lng.blank?
              redirect_to search_applications_path({:lat => lat, :lng => lng, :postcode => params[:q], :search => params[:s]})
            else
              @error = "Postcode is not valid"
            end
          rescue SocketError, Errno::ETIMEDOUT, JSON::ParserError
            @error = "Postcode is not valid"
          end
        else
          address = CGI::escape(params[:q])
          r = Location.geocode(address)
          if r.success
            redirect_to search_applications_path({:lat => r.lat, :lng => r.lng, :address => address, :search => params[:s]})
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
      @search = params[:search]
      # "anything" is our special keyword meaning don't do a full text search
      if !@search.blank? && @search.strip.downcase == "anything"
        @search = ''
      end
      @lat = params[:lat]
      @lng = params[:lng]
      url = "#{MySociety::Config::get('MAPIT_URL')}/point/4326/#{@lng},#{@lat}"
      begin
        result = HTTParty.get(url)
        content = result.body
        data = JSON.parse(content)
        @authorities = find_planning_authorities(data)
      rescue SocketError, Errno::ETIMEDOUT, JSON::ParserError
        # TBD
      end
      return false
    end

    protected

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