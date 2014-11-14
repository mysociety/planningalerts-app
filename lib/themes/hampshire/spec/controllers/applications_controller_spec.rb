require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper.rb'))
require "#{Rails.root.to_s}/lib/themes/hampshire/models/hampshire_search.rb"

describe ApplicationsController do
  let(:lat) { "51.06254955783433" }
  let(:lng) { "-1.319368478028908" }
  let(:rushmoor) { {:name => "Rushmoor Borough Council", :id => 42} }

  before(:each) do
    # force the use of the Hampshire theme
    ThemeChooser.stub(:themer_from_request).and_return(HampshireTheme.new)
  end

  context "overridden search action" do
    it "should assign the list of categories" do
      get :search
      expect(assigns(:categories)).to eq Configuration::THEME_HAMPSHIRE_CATEGORIES
    end

    it "should assign a list of categories as json for the javascript" do
      get :search
      expect(assigns(:categories_json)).to eq Configuration::THEME_HAMPSHIRE_CATEGORIES.as_json
    end

    context 'matching a MapIt authority' do
      before :each do
        @stub_search = stub(:valid? => true,
                           :perform_search => stub(:total_pages => 1,
                                                   :to_json => []),
                           :is_location_search? => true, :authorities => [rushmoor])
        HampshireSearch.should_receive(:new)
                       .and_return(@stub_search)
      end

      context "the authority has a valid MapIt id" do
        it "should find the authority via a MapIt id lookup" do
          fake_authority = mock_model(Application)
          Authority.should_receive(:find_by_mapit_id).with(42).and_return(fake_authority)
          get :search, {:location => 'GU14 6AZ'}
          expect(assigns(:authority)).to eq fake_authority
        end
      end

      context "the authority does not have a valid MapIt id" do
        it "should find the authority via a full name match" do
          fake_authority = mock_model(Application)
          Authority.should_receive(:find_by_mapit_id).with(42).and_return(nil)
          Authority.should_receive(:find_by_full_name).with('Rushmoor Borough Council').and_return(fake_authority)
          get :search, {:location => 'GU14 6AZ'}
          expect(assigns(:authority)).to eq fake_authority
        end
      end
    end

    context "deciding whether to show results" do
      before(:each) do

      end

      context "on the initial search page" do
        it "should default to not showing any results" do
          HampshireSearch.should_not_receive(:new)
          get :search
          expect(assigns(:show_results)).to eq false
        end

        it "should show the results view if we ask for them" do
          HampshireSearch.should_not_receive(:new)
          get :search, {:results => true}
          expect(assigns(:show_results)).to eq true
        end

        it "should show the results view if the location was valid" do
          stub_search = stub(:valid? => true,
                             :perform_search => stub(:total_pages => 1,
                                                     :to_json => []),
                             :is_location_search? => true, :authorities => [rushmoor])
          HampshireSearch.should_receive(:new)
                         .with(:location=>"GU14 6AZ", :search=> nil,
                               :status=> nil, :page=> nil)
                         .and_return(stub_search)
          get :search, {:location => 'GU14 6AZ'}
          expect(assigns(:show_results)).to eq true
        end

        it "should not show the results view if there was an error with the postcode" do
          stub_search = stub()
          HampshireSearch.should_receive(:new).and_return(stub_search)
          stub_search.should_receive(:valid?).and_return(false)
          stub_search.should_not_receive(:perform_search)
          get :search, {:location => 'GU14 6XX'}
          expect(assigns(:show_results)).to eq false
        end

        it "should not show the results view if there was an error with the address" do
          stub_search = stub()
          HampshireSearch.should_receive(:new).and_return(stub_search)
          stub_search.should_receive(:valid?).and_return(false)
          stub_search.should_not_receive(:perform_search)
          get :search, {:location => 'nowhere, nowhereland'}
          expect(assigns(:show_results)).to eq false
        end
      end

      context "on the search results page" do
        it "should show the results view if there was an error with the postcode" do
          stub_search = stub()
          HampshireSearch.should_receive(:new).and_return(stub_search)
          stub_search.should_receive(:valid?).and_return(false)
          stub_search.should_not_receive(:perform_search)
          get :search, {:location => 'GU14 6XX', :results => true}
          expect(assigns(:show_results)).to eq true
        end

        it "should show the results view if there was an error with the address" do
          stub_search = stub()
          HampshireSearch.should_receive(:new).and_return(stub_search)
          stub_search.should_receive(:valid?).and_return(false)
          stub_search.should_not_receive(:perform_search)
          get :search, {:location => 'nowhere, nowhereland', :results => true}
          expect(assigns(:show_results)).to eq true
        end
      end
    end

    context "deciding whether to show the map" do
      let(:stub_search) do
        stub(:perform_search => stub(:total_pages => 1, :to_json => []),
             :valid? => true)
      end

      before do
        HampshireSearch.stub(:new).and_return(stub_search)
      end

      it "should mark the map display as possible if there's a location" do
        stub_search.stub(:is_location_search? => true, :authorities => [rushmoor])
        get :search, {:location => 'GU14 6AZ'}
        expect(assigns(:map_display_possible)).to eq true
      end

      it "should mark the map display as not possible if there's no location" do
        stub_search.stub(:is_location_search? => false, :authorities => [rushmoor])
        get :search, {:search => 'test'}
        expect(assigns(:map_display_possible)).to eq false
      end

      it "should display the list if asked" do
        stub_search.stub(:is_location_search? => true, :authorities => [rushmoor])
        get :search, {:location => 'GU14 6AZ', :display => 'list'}
        expect(assigns(:display)).to eq 'list'
      end

      it "should display the map if asked" do
        stub_search.stub(:is_location_search? => true, :authorities => [rushmoor])
        get :search, {:location => 'GU14 6AZ', :display => 'map'}
        expect(assigns(:display)).to eq 'map'
      end
    end

    context "searching" do
      let(:stub_search_results) { stub(:total_pages => 1, :to_json => []) }
      let(:stub_search) do
        stub(:perform_search => stub_search_results,
             :valid? => true,
             :is_location_search? => false,
             :authorities => [rushmoor])
      end

      before do
        HampshireSearch.stub(:new).and_return(stub_search)
      end

      it 'should assign a search model to the view if a search is done' do
        get :search, {:search => "test"}
        expect(assigns(:search)).to eq stub_search
      end

      it "should not assign a search model to the view if no search is done" do
        get :search
        expect(assigns(:search)).to eq nil
      end

      it 'should pass the page param through to the search' do
        HampshireSearch.should_receive(:new)
                       .with(:location =>"GU14 6AZ", :search => 'test',
                             :status => nil, :page => "2")
                       .and_return(stub_search)
        stub_search.stub(:is_location_search? => true)
        get :search, {:search => 'test', :location => 'GU14 6AZ', :page => 2}
      end

      it "should assign matching applications if a search is done" do
        get :search, {:search => "test"}
        expect(assigns(:applications)).to eq stub_search_results
      end

      it "should assign matching applications as a JSON object" do
        get :search, {:search => "test"}
        expect(assigns(:applications_json)).to eq stub_search_results.to_json
      end

      it "should do a new search to get all applications if there's more than one page and we're on the map" do
        # total_pages tells the controller it needs to do a new search to get
        # everything for the json
        search_results = stub(:total_pages => 2, :to_json => [])
        stub_search.stub(:is_location_search? => true)
        stub_search.should_receive(:perform_search)
                   .with()
                   .and_return(search_results)
        stub_search.should_receive(:perform_search)
                   .with({:per_page => 1000, :page => 1})
                   .and_return(search_results)
        get :search, {:search => "test"}
      end

      context "creating a back to search link" do
        it 'should assign the search parameters' do
          stub_search.stub(:is_location_search? => true)
          get :search, {:search => 'anything', :location => 'GU14 6XX', :results => true, :page => 1, :status => 'all'}
          expected_params = {
            "search_search" => 'anything',
            "search_location" => 'GU14 6XX',
            "search_results" => true,
            "search_page" => "1",
            "search_status" => 'all'
          }
          expect(assigns(:return_to_search_params)).to eq expected_params
        end

        it 'should ignore other parameters' do
          get :search, {:xss => true, :search => 'anything', :location => 'GU14 6XX', :results => true, :page => 1, :status => 'all'}
          expected_params = {
            "search_search" => 'anything',
            "search_location" => 'GU14 6XX',
            "search_results" => true,
            "search_page" => "1",
            "search_status" => 'all'
          }
          expect(assigns(:return_to_search_params)).to eq expected_params
        end
      end
    end
  end

  describe "decorated show action" do
    it "should assign the return to search url" do
      app = mock_model(Application, :address => "Address", :date_scraped => Date.new(2010,1,1),
        :description => "foo", :location => nil, :find_all_nearest_or_recent => [])
      Application.should_receive(:find).with("1").and_return(app)

      get :show, {:id => 1, :search_search => 'anything', :search_location => 'GU146XX', :search_results => true, :search_page => 1, :search_status => 'all'}

      expected_url = '/applications/search?location=GU146XX&page=1&results=true&search=anything&status=all'
      expect(assigns(:return_to_search_url)).to eq expected_url
    end

    it "should ignore other parameters for return to search url" do
      app = mock_model(Application, :address => "Address", :date_scraped => Date.new(2010,1,1),
        :description => "foo", :location => nil, :find_all_nearest_or_recent => [])
      Application.should_receive(:find).with("1").and_return(app)

      get :show, {:id => 1, :search_xss => true, :search_search => 'anything', :search_location => 'GU146XX', :search_results => true, :search_page => 1, :search_status => 'all'}

      expected_url = '/applications/search?location=GU146XX&page=1&results=true&search=anything&status=all'
      expect(assigns(:return_to_search_url)).to eq expected_url
    end
  end
end