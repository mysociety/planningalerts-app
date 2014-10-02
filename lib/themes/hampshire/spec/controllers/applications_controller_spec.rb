require File.expand_path(File.join(File.dirname(__FILE__),'..','..','..','..','..','spec','spec_helper.rb'))

describe ApplicationsController do
  let(:lat) { "51.06254955783433" }
  let(:lng) { "-1.319368478028908" }

  before(:each) do
    ThemeChooser.stub(:themer_from_request).and_return(HampshireTheme.new)
  end

  context "overridden search action" do
    it 'should assign search to the view if search is passed in' do
      get :search, {:search => "test"}
      expect(assigns(:search)).to eq "test"

      get :search
      expect(assigns(:search)).to eq nil
    end

    it 'should blank the search value if passed "anything"' do
      get :search, {:search => "anything"}
      expect(assigns(:search)).to eq ""
    end

    it 'should assign latlng to the view if passed in' do
      VCR.use_cassette('hampshire_theme') do
        get :search, {:lat => lat, :lng => lng}
      end
      expect(assigns(:lat)).to eq lat
      expect(assigns(:lng)).to eq lng
    end

    it 'should pass the page param through to the search' do
      expected_params = {:per_page=>10, :order=>{:date_scraped=>:desc}, :page=>'2'}
      Application.should_receive(:search).
        with('test', expected_params).
        and_return([])

      VCR.use_cassette('hampshire_theme') do
        get :search, {:search => 'test', :lat => lat, :lng => lng, :page => 2}
      end
    end

    it 'should filter the search on the authority facet if passed authority' do
      authority = 'Rushmoor Borough Council'
      expected_params = {:per_page=>10, :order=>{:date_scraped=>:desc}, :page=>nil, :with => {:authority_facet => Zlib.crc32(authority)}}
      Application.should_receive(:search).
        with('test', expected_params).
        and_return([])

      VCR.use_cassette('hampshire_theme') do
        get :search, {:search => 'test', :lat => lat, :lng => lng, :authority => authority}
      end
    end
  end
end