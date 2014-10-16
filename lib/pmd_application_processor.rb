class PMDApplicationProcessor
  # A helper class to extract information from a PublishMyData site

  @@resource_url =  'http://hantshub-planning.publishmydata.com/resource.json'

  def self.extract_description(application)
    description = nil
    if application['http://data.hampshirehub.net/def/planning/hasCaseText']
      description = application['http://data.hampshirehub.net/def/planning/hasCaseText'][0]['@value']
    end
    return description
  end

  def self.extract_status(decision)
    status = "In progress"
    if decision
      if decision['http://data.hampshirehub.net/def/planning/decisionIssued']
        outcome = decision['http://data.hampshirehub.net/def/planning/decisionIssued'][0]['@id']
        case outcome
        when 'http://opendatacommunities.org/def/concept/planning/decision-issued/approve'
          status = "Approved"
        when 'http://opendatacommunities.org/def/concept/planning/decision-issued/refuse'
          status = "Refused"
        else
          warn "unknown status - #{outcome}, from #{decision['@id']}"
        end
      else
        # hmm, data glitch? No decisionIssued in the decision data :(
        # or maybe this is when it's been decided but the decision hasn't
        # been made public yet. Default to In Progress.
      end
    end
    return status
  end

  def self.extract_decision_date(decision, status)
    decision_date = nil
    # In Progress applications in theory don't have a decision, but some weird
    # ones do, so we have to guard against them
    if decision and status != "In progress"
      # noticeDate is the official date that notice of the decision is
      # given to the applicant
      if decision['http://data.hampshirehub.net/def/planning/noticeDate']
        decision_date = decision['http://data.hampshirehub.net/def/planning/noticeDate'][0]['@value']
        decision_date = Time.iso8601(decision_date)
      end
    end
    return decision_date
  end

  def self.extract_delayed(application, decision, status, decision_date)
    delayed = nil

    # Use the decision_date if we're given it, otherwise we'll compare
    # the target date to Now to see if it's late
    unless decision_date
      decision_date = Time.now
    end

    # Work out when the application should have been decided by. If there's a
    # decision, we assume that the date given on that as a target is better
    # than the target date on the application, though you'd think they'd be
    # the same.
    if decision and decision['http://data.hampshirehub.net/def/planning/targetDate']
      target_date = decision['http://data.hampshirehub.net/def/planning/targetDate'][0]['@value']
      target_date = Time.iso8601(target_date)
    elsif application['http://data.hampshirehub.net/def/planning/targetDate']
      target_date = application['http://data.hampshirehub.net/def/planning/targetDate'][0]['@value']
      target_date = Time.iso8601(target_date)
    else
      target_date = nil
    end

    if target_date
      delayed = target_date < decision_date
    end

    return delayed
  end

  def self.extract_address(application)
    # Pull in the localisation record
    place_json = RestClient::Request.new(
      :method => :get,
      :url => @@resource_url,
      :headers => {
        :params => {
            :uri => application['http://schema.org/location'][0]['@id']
        },
      },
      :user => Configuration::PUBLISHMYDATA_USER,
      :password => Configuration::PUBLISHMYDATA_PASSWORD,
    ).execute
    # the "resource" endpoint returns an array despite not being plural
    JSON.parse(place_json)[0]
  end

  def self.extract_location(place)
    # Some places, e.g http://data.hampshirehub.net/id/planning-application/district-council/rushmoor/14/00311/CONDPP/location
    # don't have easting/northings
    location = nil
    if place['http://data.ordnancesurvey.co.uk/ontology/spatialrelations/easting'] \
       and place['http://data.ordnancesurvey.co.uk/ontology/spatialrelations/northing']
      sleep(0.33)
      location = GlobalConvert::Location.new(
        input: {
          projection: :osgb36,
          lon: place['http://data.ordnancesurvey.co.uk/ontology/spatialrelations/easting'][0]['@value'],
          lat: place['http://data.ordnancesurvey.co.uk/ontology/spatialrelations/northing'][0]['@value']
        },
        output: {
          projection: :wgs84
        }
      )
    end
    return location
  end

  def self.extract_decision(application)
    decision = nil
    if application['http://data.hampshirehub.net/def/planning/hasDecision']
      decision_json = RestClient::Request.new(
        :method => :get,
        :url => @@resource_url,
        :headers => {
          :params => {
              :uri => application['http://data.hampshirehub.net/def/planning/hasDecision'][0]['@id']
          },
        },
        :user => Configuration::PUBLISHMYDATA_USER,
        :password => Configuration::PUBLISHMYDATA_PASSWORD,
      ).execute
      decision = JSON.parse(decision_json)[0]
    end
    return decision
  end
end