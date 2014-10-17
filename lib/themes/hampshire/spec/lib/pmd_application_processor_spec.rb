require 'spec_helper'

describe PMDApplicationProcessor do

  context 'when extracting the description' do
    let :application do
      {
        'http://data.hampshirehub.net/def/planning/hasCaseText' => [{'@value' => 'test description'}]
      }
    end

    it 'should extract the description' do
      description = PMDApplicationProcessor.extract_description(application)
      expect(description).to eq('test description')
    end

    it 'should default to nil' do
      description = PMDApplicationProcessor.extract_description({})
      expect(description).to eq(nil)
    end
  end

  context 'when extracting the address and location' do
    let :application do
      {
        'http://schema.org/location' => [
          {
            '@id' => 'http://data.hampshirehub.net/id/planning-application/district-council/rushmoor/12/00430/REVPP/location'
          }
        ]
      }
    end

    let :place do
      {
        'http://data.ordnancesurvey.co.uk/ontology/spatialrelations/northing' => [{'@value' => 155450}],
        'http://data.ordnancesurvey.co.uk/ontology/spatialrelations/easting' => [{'@value' => 486405}]
      }
    end

    it 'should extract the address' do
      VCR.use_cassette('pmd_application_processor') do
        address = PMDApplicationProcessor.extract_address(application)
        expect(address['http://data.ordnancesurvey.co.uk/ontology/spatialrelations/northing'][0]['@value']).to eq(155450)
        expect(address['http://data.ordnancesurvey.co.uk/ontology/spatialrelations/easting'][0]['@value']).to eq(486405)
        expect(address['http://www.w3.org/2000/01/rdf-schema#label'][0]['@value']).to eq('44 Invincible Road, Farnborough, Hampshire, GU14 7ST')
      end
    end

    it 'should extract the location' do
      location = PMDApplicationProcessor.extract_location(place)
      expect(location[:lat]).to be_within(0.001).of(51.2916)
      expect(location[:lng]).to be_within(0.001).of(-0.7622)
    end

    it 'should ignore applications with no or missing location info' do
      location = PMDApplicationProcessor.extract_location({
        'http://data.ordnancesurvey.co.uk/ontology/spatialrelations/northing' => [{'@value' => 155450}]
      })
      expect(location).to eq(nil)
      location = PMDApplicationProcessor.extract_location({
        'http://data.ordnancesurvey.co.uk/ontology/spatialrelations/easting' => [{'@value' => 486405}]
      })
      expect(location).to eq(nil)
      location = PMDApplicationProcessor.extract_location({})
      expect(location).to eq(nil)
    end
  end

  context 'when extracting the decision' do
    let :application do
      {
        'http://data.hampshirehub.net/def/planning/hasDecision' => [{'@id' => 'http://data.hampshirehub.net/id/planning-application/district-council/rushmoor/12/00430/REVPP/decision'}]
      }
    end

    it 'should extract the decision' do
      VCR.use_cassette('pmd_application_processor') do
        decision = PMDApplicationProcessor.extract_decision(application)
        expect(decision['http://data.hampshirehub.net/def/planning/decisionIssued'][0]['@id']).to eq('http://opendatacommunities.org/def/concept/planning/decision-issued/approve')
        expect(decision['http://data.hampshirehub.net/def/planning/targetDate'][0]['@value']).to eq('2013-12-23T00:00:00Z')
        expect(decision['http://data.hampshirehub.net/def/planning/noticeDate'][0]['@value']).to eq('2014-07-21T01:00:00+01:00')
      end
    end

    it 'should ignore applications without a decision' do
      decision = PMDApplicationProcessor.extract_decision({})
      expect(decision).to eq(nil)
    end
  end

  context 'when extracting the status' do

    let :approved_decision do
      {
        'http://data.hampshirehub.net/def/planning/decisionIssued' => [
          {
            '@id' => 'http://opendatacommunities.org/def/concept/planning/decision-issued/approve'
          }
        ],
        'http://data.hampshirehub.net/def/planning/targetDate' => [
          {
            '@value' => '2013-12-23T00:00:00Z',
            '@type' => 'http://www.w3.org/2001/XMLSchema#dateTime'
          }
        ],
        'http://data.hampshirehub.net/def/planning/noticeDate' => [
          {
            '@value' => '2014-07-21T01:00:00+01:00',
            '@type' => 'http://www.w3.org/2001/XMLSchema#dateTime'
          }
        ]
      }
    end

    let :refused_decision do
      {
        'http://data.hampshirehub.net/def/planning/decisionIssued' => [
          {
            '@id' => 'http://opendatacommunities.org/def/concept/planning/decision-issued/refuse'
          }
        ],
        'http://data.hampshirehub.net/def/planning/targetDate' => [
          {
            '@value' => '2013-12-23T00:00:00Z',
            '@type' => 'http://www.w3.org/2001/XMLSchema#dateTime'
          }
        ],
        'http://data.hampshirehub.net/def/planning/noticeDate' => [
          {
            '@value' => '2014-07-21T01:00:00+01:00',
            '@type' => 'http://www.w3.org/2001/XMLSchema#dateTime'
          }
        ]
      }
    end

    let :unknown_decision do
      {
        'http://data.hampshirehub.net/def/planning/targetDate' => [
          {
            '@value' => '2013-12-23T00:00:00Z',
            '@type' => 'http://www.w3.org/2001/XMLSchema#dateTime'
          }
        ],
        'http://data.hampshirehub.net/def/planning/noticeDate' => [
          {
            '@value' => '2014-07-21T01:00:00+01:00',
            '@type' => 'http://www.w3.org/2001/XMLSchema#dateTime'
          }
        ]
      }
    end

    let :unrecognised_decision do
      {
        'http://data.hampshirehub.net/def/planning/decisionIssued' => [
          {
            '@id' => 'http://opendatacommunities.org/def/concept/planning/decision-issued/quibble'
          }
        ],
        'http://data.hampshirehub.net/def/planning/targetDate' => [
          {
            '@value' => '2013-12-23T00:00:00Z',
            '@type' => 'http://www.w3.org/2001/XMLSchema#dateTime'
          }
        ],
        'http://data.hampshirehub.net/def/planning/noticeDate' => [
          {
            '@value' => '2014-07-21T01:00:00+01:00',
            '@type' => 'http://www.w3.org/2001/XMLSchema#dateTime'
          }
        ]
      }
    end

    it 'should extract the status' do
      status = PMDApplicationProcessor.extract_status(approved_decision)
      expect(status).to eq('Approved')
    end

    it 'should default to In Progress' do
      status = PMDApplicationProcessor.extract_status(nil)
      expect(status).to eq('In progress')
    end

    it 'should find refused applications' do
      status = PMDApplicationProcessor.extract_status(refused_decision)
      expect(status).to eq('Refused')
    end

    it 'should return In Progress for unrecognised statuses' do
      status = PMDApplicationProcessor.extract_status(unrecognised_decision)
      expect(status).to eq('In progress')
    end

    it 'should return In Progress when theres a decision but no decisionIssued' do
      status = PMDApplicationProcessor.extract_status(unknown_decision)
      expect(status).to eq('In progress')
    end
  end

  context 'when extracting the decision date' do
    let :approved_decision do
      {
        'http://data.hampshirehub.net/def/planning/decisionIssued' => [
          {
            '@id' => 'http://opendatacommunities.org/def/concept/planning/decision-issued/approve'
          }
        ],
        'http://data.hampshirehub.net/def/planning/targetDate' => [
          {
            '@value' => '2013-12-23T00:00:00Z',
            '@type' => 'http://www.w3.org/2001/XMLSchema#dateTime'
          }
        ],
        'http://data.hampshirehub.net/def/planning/noticeDate' => [
          {
            '@value' => '2014-07-21T01:00:00+01:00',
            '@type' => 'http://www.w3.org/2001/XMLSchema#dateTime'
          }
        ],
        # We shouldn't use this date, so it's here to check we don't
        'http://data.hampshirehub.net/def/planning/decisionDate' => [
          {
            '@value' => '2014-07-19T01:00:00+01:00',
            '@type' => 'http://www.w3.org/2001/XMLSchema#dateTime'
          }
        ]
      }
    end

    it 'should extract the decision date' do
      decision_date = PMDApplicationProcessor.extract_decision_date(approved_decision, 'Approved')
      expect(decision_date).to eq(Time.iso8601('2014-07-21T01:00:00+01:00'))
    end

    it 'should default to nil' do
      decision_date = PMDApplicationProcessor.extract_decision_date(nil, 'Approved')
      expect(decision_date).to eq(nil)
    end

    it 'should should ignore In Progress applications' do
      decision_date = PMDApplicationProcessor.extract_decision_date(nil, 'In progress')
      expect(decision_date).to eq(nil)
    end
  end

  context 'when extracting the delayed status' do
    let :decision do
      {
        'http://data.hampshirehub.net/def/planning/targetDate' => [
          {
            '@value' => '2013-12-23T00:00:00Z',
            '@type' => 'http://www.w3.org/2001/XMLSchema#dateTime'
          }
        ]
      }
    end

    let :application do
      {
        # This is here so that we can test the processor doesn't prefer this date
        'http://data.hampshirehub.net/def/planning/targetDate' => [
          {
            '@value' => '2014-07-21T01:00:00+01:00'
          }
        ]
      }
    end

    it 'should extract the delayed status' do
      delayed_decision_date = Time.iso8601('2014-07-21T01:00:00+01:00')
      delayed = PMDApplicationProcessor.extract_delayed(application, decision, 'Approved', delayed_decision_date)
      expect(delayed).to eq(true)
    end

    it 'should recognise not-delayed applications' do
      on_time_decision_date = Time.iso8601('2013-12-22T00:00:00Z')
      delayed = PMDApplicationProcessor.extract_delayed(application, decision, 'Approved', on_time_decision_date)
      expect(delayed).to eq(false)
    end

    it 'should allow decisions on the target date' do
      on_time_decision_date = Time.iso8601('2013-12-23T00:00:00Z')
      delayed = PMDApplicationProcessor.extract_delayed(application, decision, 'Approved', on_time_decision_date)
      expect(delayed).to eq(false)
    end

    it 'should fallback to the applications target date' do
      on_time_decision_date = Time.iso8601('2014-07-21T01:00:00+01:00')
      delayed = PMDApplicationProcessor.extract_delayed(application, {}, 'Approved', on_time_decision_date)
      expect(delayed).to eq(false)
    end

    it 'should compare to Now if there is no decision date' do
      tomorrow_application = {
        'http://data.hampshirehub.net/def/planning/targetDate' => [
          {
            '@value' => (Time.now + 1.days).iso8601
          }
        ]
      }
      delayed = PMDApplicationProcessor.extract_delayed(tomorrow_application, {}, 'In progress', nil)
      expect(delayed).to eq(false)

      yesterday_application = {
        'http://data.hampshirehub.net/def/planning/targetDate' => [
          {
            '@value' => (Time.now - 1.days).iso8601
          }
        ]
      }
      delayed = PMDApplicationProcessor.extract_delayed(yesterday_application, {}, 'In progress', nil)
      expect(delayed).to eq(true)
    end

    it 'should return nil when there is no target date' do
      delayed = PMDApplicationProcessor.extract_delayed({}, {}, 'Approved', nil)
      expect(delayed).to eq(nil)
    end

  end

  context 'when extracting the council category' do
    let :application do
      {
        'http://data.hampshirehub.net/def/planning/hasDevelopmentCategory' => [
          {
            '@id' => 'http://opendatacommunities.org/def/concept/planning/application/6000/6014'
          }
        ]
      }
    end

    it 'should extract the council category' do
      council_category = PMDApplicationProcessor.extract_council_category(application)
      expect(council_category).to eq('http://opendatacommunities.org/def/concept/planning/application/6000/6014')
    end

    it 'should default to nil' do
      council_category = PMDApplicationProcessor.extract_council_category({})
      expect(council_category).to eq(nil)
    end
  end

  context 'when extracting categories' do
    it 'should use the classifier for household developments' do
      classifier = mock
      classifier.should_receive(:classify).with('test description').and_return('test')
      category = PMDApplicationProcessor.extract_category(
        'http://opendatacommunities.org/def/concept/planning/application/6000/6014',
        'test description',
        classifier
      )
      expect(category).to eq('test')
    end

    it 'should only try to classify householder applications with a description' do
      classifier = mock
      classifier.should_not_receive(:classify)
      category = PMDApplicationProcessor.extract_category(
        'http://opendatacommunities.org/def/concept/planning/application/6000/6014',
        nil,
        classifier
      )
      expect(category).to eq(nil)
    end

    it 'should recognise Major Developments' do
      classifier = mock
      classifier.should_not_receive(:classify)
      major_categories = ['6001', '6002', '6003', '6004', '6005', '6006']
      major_categories.each do |category|
        category = PMDApplicationProcessor.extract_category(
          "http://opendatacommunities.org/def/concept/planning/application/6000/#{category}",
          'test description',
          classifier
        )
        expect(category).to eq('Major Developments')
      end
    end

    it 'should recognise Trees and Hedges' do
      classifier = mock
      classifier.should_not_receive(:classify)
      tree_categories = ['6019', '6022']
      tree_categories.each do |category|
        category = PMDApplicationProcessor.extract_category(
          "http://opendatacommunities.org/def/concept/planning/application/6000/#{category}",
          'test description',
          classifier
        )
        expect(category).to eq('Trees and Hedges')
      end
    end

    it 'should ignore applications without a developmentCategory' do
      classifier = mock
      classifier.should_not_receive(:classify)
      category = PMDApplicationProcessor.extract_category(nil, 'test description', classifier)
      expect(category).to eq(nil)
    end

    it 'should ignore applications that are not householder or Trees or Major' do
      classifier = mock
      classifier.should_not_receive(:classify)
      other_categories = ['6007', '6008', '6009', '6010', '6011', '6012',
                          '6013', '6015', '6016', '6017', '6018', '6020',
                          '6021', '6023', '6024', '6025', '6026', '6027',
                          '6028', '6029', '6030']
      other_categories.each do |category|
        category = PMDApplicationProcessor.extract_category(
          "http://opendatacommunities.org/def/concept/planning/application/6000/#{category}",
          'test description',
          classifier
        )
        expect(category).to eq(nil)
      end
    end
  end
end