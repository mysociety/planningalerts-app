require File.expand_path(File.join(File.dirname(__FILE__),'..','..','..','..','..','spec','spec_helper.rb'))
require "#{Rails.root.to_s}/lib/themes/hampshire/models/hampshire_search.rb"

describe ApplicationsController do
  let(:lat) { "51.06254955783433" }
  let(:lng) { "-1.319368478028908" }

  before(:each) do
    # force the use of the Hampshire theme
    ThemeChooser.stub(:themer_from_request).and_return(HampshireTheme.new)
  end

  context "overridden search action" do
    context "deciding whether to show results" do
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
                             :is_location_search? => true)
          HampshireSearch.should_receive(:new)
                         .with(:location=>"GU14 6AZ", :search=> nil,
                               :authority=> nil, :status=> nil, :page=> nil)
                         .and_return(stub_search)
          get :search, {:location => 'GU14 6AZ'}
          expect(assigns(:show_results)).to eq true
        end

        it "should show the results view if an authority was specified" do
          stub_search = stub(:valid? => true,
                             :perform_search => stub(:total_pages => 1, :to_json => []),
                             :is_location_search? => false)
          HampshireSearch.should_receive(:new)
                         .with(:authority => 'Rushmoor Borough Council',
                               :search=> nil, :location=> nil, :status=> nil,
                               :page=> nil)
                         .and_return(stub_search)
          get :search, {:authority => 'Rushmoor Borough Council'}
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
        stub_search.stub(:is_location_search? => true)
        get :search, {:location => 'GU14 6AZ'}
        expect(assigns(:map_display_possible)).to eq true
      end

      it "should mark the map display as not possible if there's no location" do
        stub_search.stub(:is_location_search? => false)
        get :search, {:search => 'test'}
        expect(assigns(:map_display_possible)).to eq false
      end

      it "should display the list if asked" do
        stub_search.stub(:is_location_search? => true)
        get :search, {:location => 'GU14 6AZ', :display => 'list'}
        expect(assigns(:display)).to eq 'list'
      end

      it "should display the map if asked" do
        stub_search.stub(:is_location_search? => true)
        get :search, {:location => 'GU14 6AZ', :display => 'map'}
        expect(assigns(:display)).to eq 'map'
      end
    end

    context "searching" do
      let(:stub_search_results) { stub(:total_pages => 1, :to_json => []) }
      let(:stub_search) do
        stub(:perform_search => stub_search_results,
             :valid? => true,
             :is_location_search? => false)
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
                             :authority => nil, :status => nil, :page => "2")
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
    end
  end
end