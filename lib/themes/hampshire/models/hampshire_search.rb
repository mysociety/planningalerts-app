class HampshireSearch < ApplicationSearch
  attr_accessor :search, :page, :location, :lat, :lng, :authority, :postcode,
                :address, :status

  validate :valid_location

  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end

    # "anything" is our special keyword meaning don't do a full text search
    if !@search.blank? && @search.strip.downcase == "anything"
      @search = nil
    end
  end

  def authorities
    authorities = []
    result = MySociety::MaPit.call('/point', "4326/#{@lng},#{@lat}")
    if result == :service_unavailable or result == :bad_request or result == :not_found
      # TBD
    else
      authorities = find_planning_authorities(result)
    end
    return authorities
  end

  def is_location_search?
    @lat.present? and @lng.present?
  end

  def perform_search(override_params={})
    search_params = {:per_page => Application.per_page,
                     :order => {:date_scraped => :desc},
                     :page => @page}
    search_params.merge!(override_params)
    with_params = {}
    if @authority and !is_location_search?
      authority_facet = Zlib.crc32(CGI::unescape(@authority))
      with_params[:authority_facet] = authority_facet
    end
    if is_location_search?
      search_params[:geo] = [lat_in_radians, lng_in_radians]
      with_params['@geodist'] = 0.0..search_range
    end
    # uncomment once we've got categories wired up
    # if params[:category]
    #   with_params[:category_facet] = Zlib.crc32(params[:category])
    # end

    # using this as a filter could cause us problems if we always
    # want to be able to display counts of all 3 facets
    # might switch this off in the end
    if @status
      with_params[:status_facet] = Zlib.crc32(@status)
    end
    unless with_params.empty?
      search_params[:with] = with_params
    end
    if @search.nil?
      return Application.search search_params
    else
      return Application.search @search, search_params
    end
  end

  protected

  def lat_in_radians
    @lat.to_f / 180 * Math::PI
  end

  def lng_in_radians
    @lng.to_f / 180 * Math::PI
  end

  def search_range
    distance_in_miles = ::Configuration::THEME_HAMPSHIRE_SEARCH_RADIUS
    # convert miles to metres
    return distance_in_miles.to_f * 1609.344
  end

  def valid_location
    # Searches without a location are allowed
    return true if @location.blank?
    if MySociety::Validate.is_valid_postcode(@location)
      valid_postcode(@location)
    else
      valid_address(@location)
    end
  end

  def valid_postcode(postcode)
    stripped_postcode = postcode.gsub(" ", "")
    result = MySociety::MaPit.call('postcode', stripped_postcode)
    if result == :service_unavailable or result == :bad_request
      errors.add(:postcode, "We're sorry, something went wrong looking up your postcode, could you try again?")
    elsif result == :not_found
      errors.add(:postcode, "Sorry, it doesn't look like that's a valid postcode.")
    else
      @postcode = postcode
      @lat = result['wgs84_lat']
      @lng = result['wgs84_lon']
    end
  end

  def valid_address(address)
    r = Location.geocode(CGI::escape(address))
    if r.success
      @address = address
      @lat = r.lat
      @lng = r.lng
    else
      errors.add(:address, "Sorry, we couldn't find that address.")
    end
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