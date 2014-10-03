require File.expand_path(File.join(File.dirname(__FILE__),'..','..','..','..','..','spec','spec_helper.rb'))

describe ApplicationsController do
  let(:lat) { "51.06254955783433" }
  let(:lng) { "-1.319368478028908" }

  before(:each) do
    # force the use of the Hampshire theme
    ThemeChooser.stub(:themer_from_request).and_return(HampshireTheme.new)
  end

  context "overridden search action" do
    context "passing params" do
      it 'should assign search to the view if search is passed in' do
        get :search, {:search => "test"}
        expect(assigns(:search)).to eq "test"

        get :search
        expect(assigns(:search)).to eq nil
      end

      it 'should assign nil the search value if passed "anything"' do
        get :search, {:search => "anything"}
        expect(assigns(:search)).to eq nil
      end

      it 'should assign latlng to the view if passed in' do
        Application.stub(:search)
        VCR.use_cassette('hampshire_theme') do
          get :search, {:lat => lat, :lng => lng}
        end
        expect(assigns(:lat)).to eq lat
        expect(assigns(:lng)).to eq lng
      end

      it 'should pass the page param through to the search' do
        expected_params = {:per_page => 10,
                           :order => {:date_scraped=>:desc},
                           :page => '2',
                           :geo => [0.8912096142469838, -0.023027323988630912],
                           :with => {'@geodist' => 0.0..8046.72}}
        Application.should_receive(:search).
          with('test', expected_params).
          and_return([])

        VCR.use_cassette('hampshire_theme') do
          get :search, {:search => 'test', :lat => lat, :lng => lng, :page => 2}
        end
      end
    end

    context "searching" do
      it "should search using the keyword and authority facet if passed an authority name" do
        expected_params = {:per_page => 10,
                           :order => {:date_scraped=>:desc},
                           :page => nil,
                           :with => {:authority_facet => Zlib.crc32('Rushmoor Borough Council')}}
        Application.should_receive(:search).with("tree", expected_params).and_return([])

        get :search, {:search => 'tree', :authority => "Rushmoor Borough Council"}
      end

      it "should search using the keyword and location if passed lat lng" do
        expected_params = {:per_page => 10,
                           :order => {:date_scraped=>:desc},
                           :page => nil,
                           :geo => [0.8912096142469838, -0.023027323988630912],
                           :with => {'@geodist' => 0.0..8046.72}}
        Application.should_receive(:search).with("tree", expected_params).and_return([])

        VCR.use_cassette('hampshire_theme') do
          get :search, {:search => 'tree', :lat => lat, :lng => lng}
        end
      end

      it "should prefer lat lng if passed authority and lat lng" do
        expected_params = {:per_page => 10,
                           :order => {:date_scraped=>:desc},
                           :page => nil,
                           :geo => [0.8912096142469838, -0.023027323988630912],
                           :with => {'@geodist' => 0.0..8046.72}}
        Application.should_receive(:search).with("tree", expected_params).and_return([])

        VCR.use_cassette('hampshire_theme') do
          get :search, {:search => 'tree', :authority => "Rushmoor Borough Council", :lat => lat, :lng => lng}
        end
      end

      it "should do a search without the keyword if passed 'anything' as a keyword" do
        expected_params = {:per_page => 10,
                           :order => {:date_scraped=>:desc},
                           :page => nil,
                           :geo => [0.8912096142469838, -0.023027323988630912],
                           :with => {'@geodist' => 0.0..8046.72}}
        Application.should_receive(:search).with(expected_params).and_return([])

        VCR.use_cassette('hampshire_theme') do
          get :search, {:search => 'anything', :lat => lat, :lng => lng}
        end
      end
    end
  end
end