class HampshireSearch < ApplicationSearch
  attr_accessor :search, :page, :location, :lat, :lng, :authority, :postcode,
                :address, :status, :categories, :category, :stats

  validate :valid_location

  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
    @categories = ::Configuration::THEME_HAMPSHIRE_CATEGORIES
    process_search_and_category
    process_status
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
    # note - ThinkingSphinx only honours the DESC part of the search order
    # if it is passed as a string, otherwise it defaults to ASC :o\
    # http://pat.github.io/thinking-sphinx/searching.html#sorting
    search_params = {:per_page => Application.per_page,
                     :order => "date_received DESC",
                     :page => @page}
    search_params.merge!(override_params)
    with_params = {}
    if is_location_search?
      search_params[:geo] = [lat_in_radians, lng_in_radians]
      with_params['@geodist'] = 0.0..search_range
    end
    if @category
      with_params[:category_facet] = Zlib.crc32(@category)
    end

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
      results = Application.search search_params
    else
      results = Application.search @search, search_params
    end
    @stats = calculate_stats(results) if results
    return results
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

  def process_search_and_category
    # Determine if a search string is actually a category and set an
    # appropriate instance var if so
    if @search
      # "anything" is our special keyword meaning don't do a full text search
      if @search == 'anything'
        # Essentially don't search or filter by category
        @search = nil
        @category = nil
      elsif @categories.include?(@search)
        @category = @search
        @search = nil
      else
        # Not a matching category
        @search = @search
        @category = nil
      end
    end
  end

  def process_status
    if @status == 'all'
      @status = nil
    end
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
    if !r.error
      @address = address
      @lat = r.lat
      @lng = r.lng
    else
      errors.add(:address, "Sorry, we couldn't find that address.")
    end
  end

  def calculate_stats(results)
    stats = {}
    stats[:total_results] = results.total_entries

    approved_count = results.facets[:status][Configuration::THEME_HAMPSHIRE_STATUSES['approved']].to_i
    if approved_count > 0
      stats[:percentage_approved] = (approved_count.to_f / results.total_entries * 100).round
    else
      stats[:percentage_approved] = 0
    end

    refused_count = results.facets[:status][Configuration::THEME_HAMPSHIRE_STATUSES['refused']].to_i
    if refused_count > 0
      stats[:percentage_refused] = (refused_count.to_f / results.total_entries * 100).round
    else
      stats[:percentage_refused] = 0
    end

    current_count = results.facets[:status][Configuration::THEME_HAMPSHIRE_STATUSES['pending']].to_i
    if current_count > 0
      stats[:percentage_current] = (current_count.to_f / results.total_entries * 100).round
    else
      stats[:percentage_current] = 0
    end

    stats
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