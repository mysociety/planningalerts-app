require File.expand_path(File.join(File.dirname(__FILE__),'..','..','..','..','..','spec','spec_helper.rb'))
require "#{Rails.root.to_s}/lib/themes/hampshire/models/hampshire_search.rb"
$:.push(File.join(File.dirname(__FILE__), '../../commonlib/rblib'))
require "validate.rb"
require "mapit.rb"

describe HampshireSearch do
  it "should set search to nil if nothing is supplied" do
    search = HampshireSearch.new()
    expect(search.search).to eq(nil)
  end

  it "should set search to nil if 'Anything' is supplied" do
    search = HampshireSearch.new(:search => 'Anything')
    expect(search.search).to eq(nil)
  end

  it "should set category to nil is nothing is supplied" do
    search = HampshireSearch.new()
    expect(search.category).to eq(nil)
  end

  it "should set category to nil is 'Anything' is supplied" do
    search = HampshireSearch.new(:search => 'Anything')
    expect(search.category).to eq(nil)
  end

  it "should set search to nil if a category is supplied" do
    ::Configuration::THEME_HAMPSHIRE_CATEGORIES.each do |category|
      search = HampshireSearch.new(:search => category)
      expect(search.search).to eq(nil)
    end
  end

  it "should set the category if a category is supplied" do
    ::Configuration::THEME_HAMPSHIRE_CATEGORIES.each do |category|
      search = HampshireSearch.new(:search => category)
      expect(search.category).to eq(category)
    end
  end

  it "should report that it's a location search if the lat/lng are set" do
    search = HampshireSearch.new(:lat => 1, :lng => 2)
    expect(search.is_location_search?).to eq(true)
  end

  context "when validating" do
    it "should validate the location as a postcode if it looks like one" do
      search = HampshireSearch.new(:location => 'GU14 6AZ')
      MySociety::MaPit.should_receive(:call)
                      .with('postcode', 'GU146AZ')
                      .and_return({'wgs84_lat' => 1, 'wgs84_lon' => 2})
      search.valid?
    end

    it "should validate the location as an address if it looks like one" do
      search = HampshireSearch.new(:location => 'Farnborough')
      Location.should_receive(:geocode)
              .with(CGI::escape('Farnborough'))
              .and_return(stub(:success => true, :lat => 1, :lng => 2))
      search.valid?
    end

    it "should be valid when there's no location" do
      search = HampshireSearch.new()
      expect(search.valid?).to eq(true)
    end

    it "should be valid when there's a blank location" do
      search = HampshireSearch.new(:location => '')
      expect(search.valid?).to eq(true)
    end

    context "when validating postcodes" do
      it "should assign the lat/lng from mapit if there's a result" do
        search = HampshireSearch.new(:location => 'GU14 6AZ')
        MySociety::MaPit.should_receive(:call)
                        .with('postcode', 'GU146AZ')
                        .and_return({'wgs84_lat' => 1, 'wgs84_lon' => 2})
        expect(search.valid?).to eq(true)
        expect(search.postcode).to eq('GU14 6AZ')
        expect(search.lat).to eq(1)
        expect(search.lng).to eq(2)
      end

      it "should be invalid if the postcode is not found" do
        search = HampshireSearch.new(:location => 'GU14 6AZ')
        MySociety::MaPit.should_receive(:call)
                        .with('postcode', 'GU146AZ')
                        .and_return(:not_found)
        expect(search.valid?).to eq(false)
        expect(search.postcode).to eq(nil)
        expect(search.lat).to eq(nil)
        expect(search.lng).to eq(nil)
        expect(search.errors[:postcode]).to eq(["Sorry, it doesn't look like that's a valid postcode."])
      end

      it "should be invalid if MapIt is unavailable" do
        search = HampshireSearch.new(:location => 'GU14 6AZ')
        MySociety::MaPit.should_receive(:call)
                        .with('postcode', 'GU146AZ')
                        .and_return(:service_unavailable)
        expect(search.valid?).to eq(false)
        expect(search.postcode).to eq(nil)
        expect(search.lat).to eq(nil)
        expect(search.lng).to eq(nil)
        expect(search.errors[:postcode]).to eq(["We're sorry, something went wrong looking up your postcode, could you try again?"])
      end

      it "should be invalid if MapIt doesn't like our request" do
        search = HampshireSearch.new(:location => 'GU14 6AZ')
        MySociety::MaPit.should_receive(:call)
                        .with('postcode', 'GU146AZ')
                        .and_return(:bad_request)
        expect(search.valid?).to eq(false)
        expect(search.postcode).to eq(nil)
        expect(search.lat).to eq(nil)
        expect(search.lng).to eq(nil)
        expect(search.errors[:postcode]).to eq(["We're sorry, something went wrong looking up your postcode, could you try again?"])
      end
    end

    context "when validating addresses" do
      it "should assign the lat/lng from Location if there's a result" do
        search = HampshireSearch.new(:location => 'Farnborough')
        Location.should_receive(:geocode)
                .with(CGI::escape('Farnborough'))
                .and_return(stub(:success => true, :lat => 1, :lng => 2))
        expect(search.valid?).to eq(true)
        expect(search.address).to eq('Farnborough')
        expect(search.lat).to eq(1)
        expect(search.lng).to eq(2)
      end

      it "should be invalid if the geocoder doesn't succeed" do
        search = HampshireSearch.new(:location => 'Farnborough')
        Location.should_receive(:geocode)
                .with(CGI::escape('Farnborough'))
                .and_return(stub(:success => false))
        expect(search.valid?).to eq(false)
        expect(search.address).to eq(nil)
        expect(search.lat).to eq(nil)
        expect(search.lng).to eq(nil)
        expect(search.errors[:address]).to eq(["Sorry, we couldn't find that address."])
      end
    end
  end

  context "when performing a search" do
    it "should set some sensible defaults" do
      search = HampshireSearch.new()
      expected_params = {
        :per_page => Application.per_page,
        :order => {:date_scraped => :desc},
        :page => nil
      }
      Application.should_receive(:search).with(expected_params)
      search.valid?
      search.perform_search
    end

    it "should allow its defaults to be overriden" do
      search = HampshireSearch.new()
      expected_params = {
        :per_page => 1000,
        :order => {:date_scraped => :asc},
        :page => 2
      }
      Application.should_receive(:search).with(expected_params)
      search.valid?
      search.perform_search(expected_params)
    end

    it "should add an authority facet if given an authority and no location" do
      search = HampshireSearch.new(:authority => 'Rushmoor')
      expected_params = {
        :per_page => Application.per_page,
        :order => {:date_scraped => :desc},
        :page => nil,
        :with => {:authority_facet => Zlib.crc32(CGI::unescape('Rushmoor'))}
      }
      Application.should_receive(:search).with(expected_params)
      search.valid?
      search.perform_search
    end

    it "should not add an authority facet if given an authority and a location" do
      search = HampshireSearch.new(:authority => 'Rushmoor', :location => 'GU14 6AZ')
      authority_params = {
        :per_page => Application.per_page,
        :order => {:date_scraped => :desc},
        :page => nil,
        :with => {:authority_facet => Zlib.crc32('Rushmoor')}
      }
      Application.should_not_receive(:search).with(authority_params)
      MySociety::MaPit.should_receive(:call)
                      .with('postcode', 'GU146AZ')
                      .and_return({'wgs84_lat' => 1, 'wgs84_lon' => 2})
      search.valid?
      search.perform_search
    end

    it "should do a geosearch if given a location" do
      search = HampshireSearch.new(:location => 'GU14 6AZ')
      expected_params = {
        :per_page => Application.per_page,
        :order => {:date_scraped => :desc},
        :page => nil,
        :geo=>[0.017453292519943295, 0.03490658503988659],
        :with=>{"@geodist"=>0.0..3218.688}
      }
      Application.should_receive(:search).with(expected_params)
      MySociety::MaPit.should_receive(:call)
                      .with('postcode', 'GU146AZ')
                      .and_return({'wgs84_lat' => 1, 'wgs84_lon' => 2})
      search.valid?
      search.perform_search
    end

    it "should do a keyword search if given a search string" do
      search = HampshireSearch.new(:search => 'Test')
      expected_params = {
        :per_page => Application.per_page,
        :order => {:date_scraped => :desc},
        :page => nil
      }
      Application.should_receive(:search).with('Test', expected_params)
      search.valid?
      search.perform_search
    end

    it "should do a keyword and location search if given a search string and a location" do
      search = HampshireSearch.new(:search => 'Test', :location => 'GU14 6AZ')
      expected_params = {
        :per_page => Application.per_page,
        :order => {:date_scraped => :desc},
        :page => nil,
        :geo=>[0.017453292519943295, 0.03490658503988659],
        :with=>{"@geodist"=>0.0..3218.688}
      }
      Application.should_receive(:search).with('Test', expected_params)
      MySociety::MaPit.should_receive(:call)
                      .with('postcode', 'GU146AZ')
                      .and_return({'wgs84_lat' => 1, 'wgs84_lon' => 2})
      search.valid?
      search.perform_search
    end

    it "should add the status facet if given a status" do
      search = HampshireSearch.new(:status => 'Refused')
      expected_params = {
        :per_page => Application.per_page,
        :order => {:date_scraped => :desc},
        :page => nil,
        :with => {:status_facet => Zlib.crc32('Refused')}
      }
      Application.should_receive(:search).with(expected_params)
      search.valid?
      search.perform_search
    end

    it "should add the category facet if given a category" do
      search = HampshireSearch.new(:search => 'Conservatories')
      expected_params = {
        :per_page => Application.per_page,
        :order => {:date_scraped => :desc},
        :page => nil,
        :with => {:category_facet => Zlib.crc32('Conservatories')}
      }
      Application.should_receive(:search).with(expected_params)
      search.valid?
      search.perform_search
    end

    it "should calculate search stats" do
      search = HampshireSearch.new(:search => 'Test')
      stub_search = stub(:total_entries => 50,
                         :facets => {
                           :status=>{
                              "Approved"=>30,
                              "Refused"=>5,
                              "In Progress"=>15}})
      Application.should_receive(:search).and_return(stub_search)
      search.valid?
      search.perform_search

      expect(search.stats).to be_a(Hash)
      expect(search.stats[:total_results]).to eq(50)
      expect(search.stats[:percentage_approved]).to eq(60)
      expect(search.stats[:percentage_refused]).to eq(10)
      expect(search.stats[:percentage_current]).to eq(30)
    end
  end

  context "when finding authorities" do
    it "should return a list of authorities if there's a location" do
      search = HampshireSearch.new(:location => 'GU14 6AZ')
      mock_areas = {
        "2227" => {
          "id" => 2227,
          "name" => "Hampshire County Council",
          "type" => "CTY"
        },
        "2329" => {
            "id" => 2329,
            "name" => "Eastleigh Borough Council",
            "type" => "DIS"
        }
      }
      MySociety::MaPit.should_receive(:call)
                      .with('postcode', 'GU146AZ')
                      .and_return({'wgs84_lat' => 1, 'wgs84_lon' => 2})
      MySociety::MaPit.should_receive(:call)
                      .with('/point', '4326/2,1')
                      .and_return(mock_areas)
      search.valid?
      expected_authorities = [
        {:id=>"2329", :name=>"Eastleigh Borough Council", :type=>"DIS"},
        {:id=>"2227", :name=>"Hampshire County Council", :type=>"CTY"}
      ]
      expect(search.authorities).to eq(expected_authorities)
    end

    it "should return an empty list if MapIt returns no authorities" do
      search = HampshireSearch.new(:location => 'GU14 6AZ')
      MySociety::MaPit.should_receive(:call)
                      .with('postcode', 'GU146AZ')
                      .and_return({'wgs84_lat' => 1, 'wgs84_lon' => 2})
      MySociety::MaPit.should_receive(:call)
                      .with('/point', '4326/2,1')
                      .and_return({})
      search.valid?
      expect(search.authorities).to eq([])
    end

    it "should return an empty list if MapIt errors" do
      search = HampshireSearch.new(:location => 'GU14 6AZ')
      MySociety::MaPit.should_receive(:call)
                      .with('postcode', 'GU146AZ')
                      .and_return({'wgs84_lat' => 1, 'wgs84_lon' => 2})
      MySociety::MaPit.should_receive(:call)
                      .with('/point', '4326/2,1')
                      .and_return(:service_unavailable)
      search.valid?
      expect(search.authorities).to eq([])
    end

    it "should choose DIS, NPA, UTA and CTY authorities only" do
      search = HampshireSearch.new(:location => 'GU14 6AZ')
      mock_areas = {
        "2227" => {
          "id" => 2227,
          "name" => "Hampshire County Council",
          "type" => "CTY"
        },
        "2329" => {
            "id" => 2329,
            "name" => "Eastleigh Borough Council",
            "type" => "DIS"
        },
        "2330" => {
            "id" => 2330,
            "name" => "Suprious London Borough Council",
            "type" => "LBO"
        }
      }
      MySociety::MaPit.should_receive(:call)
                      .with('postcode', 'GU146AZ')
                      .and_return({'wgs84_lat' => 1, 'wgs84_lon' => 2})
      MySociety::MaPit.should_receive(:call)
                      .with('/point', '4326/2,1')
                      .and_return(mock_areas)
      search.valid?
      expected_authorities = [
        {:id=>"2329", :name=>"Eastleigh Borough Council", :type=>"DIS"},
        {:id=>"2227", :name=>"Hampshire County Council", :type=>"CTY"}
      ]
      expect(search.authorities).to eq(expected_authorities)
    end
  end
end