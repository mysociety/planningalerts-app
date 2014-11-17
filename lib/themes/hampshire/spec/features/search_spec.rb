require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper.rb'))
require "#{Rails.root.to_s}/lib/themes/hampshire/models/hampshire_search.rb"
require 'securerandom'

feature "Custom Hampshire search pages" do
  before(:each) do
    # mock search to be overridden for specific scenarios
    @mock_search = mock_model(HampshireSearch)
    @mock_search.stub(:is_location_search?).and_return(true)
    @mock_search.stub(:lat).and_return(1)
    @mock_search.stub(:lng).and_return(2)
    @mock_search.stub(:status).and_return(nil)
    @mock_search.stub(:stats).and_return({:total_results => 0})
    @mock_search.stub(:authorities).and_return([])
  end

  def mock_search_results(number)
    mock_results = [] # IRL would be ThinkingSphinx::Search
    mock_results.stub(:current_page).and_return(1)
    if number == 0
      mock_results.stub(:to_json).and_return([])
      mock_results.stub(:total_pages).and_return(0)
    else
      mock_results.stub(:total_pages).and_return(number / (Application.per_page+1) + 1)
      mock_results.delete_if { |x| x.nil? }
      authority = Factory(:authority, :full_name => "Foo", :email => "feedback@foo.gov.au")
      applications = FactoryGirl.build_list(:application, number, council_reference: SecureRandom.hex, authority: authority, status: 'approved')
      authority.stub(:applications).and_return(applications)
    end
    mock_results.stub(:total_entries).and_return(number)
    mock_results
  end

  scenario "Invalid postcode input in the search widget" do
    VCR.use_cassette('hampshire_theme_valid_looking_invalid_postcode', :record => :once, :allow_playback_repeats => true) do
      visit search_applications_url(:host => "hampshire.127.0.0.1.xip.io:3000", :results => true, :status => "all", :location => "SW99 0AA")
    end
    expect(page).to have_content("Hmm, it looks like something's wrong.")
    expect(page).to have_content("Sorry, it doesn't look like that's a valid postcode.")
  end

  scenario "No matching results" do
    HampshireSearch.should_receive(:new).and_return(@mock_search)
    mock_results = mock_search_results(0)
    @mock_search.stub(:perform_search).and_return(mock_results)

    visit search_applications_url(:host => "hampshire.127.0.0.1.xip.io:3000", :results => true, :status => "all", :location => "GU14 7ST")

    expect(page).to have_content("Sorry, no results matched that search, perhaps try again with less specific keywords, or in a different location?")
    expect(page).to have_content("Found 0 matching planning applications")
    expect(page).to have_no_selector('div#sidebar-stats')
  end

  scenario "4 matching results with a matching MapIt authority (as a list)" do
    mock_results = mock_search_results(4)
    @mock_search.stub(:stats).and_return({:total_results => 4})
    @mock_search.stub(:authorities).and_return([{:full_name => "Foo"}])

    HampshireSearch.should_receive(:new).and_return(@mock_search)
    @mock_search.stub(:perform_search).and_return(mock_results)

    visit search_applications_url(:host => 'hampshire.127.0.0.1.xip.io:3000', :results => true, :status => 'all', :location => 'GU14 7ST', :display => 'list')
    expect(page).to have_content('Show results on a map')
    expect(page).to have_content('See more statistics for Foo')
    expect(page).to have_content("Found 4 matching planning applications")
    expect(page).to have_selector('div#sidebar-stats')
    expect(page).to have_no_selector('div.pagination')
  end

  scenario "results filtered on status" do
    mock_results = mock_search_results(4)
    @mock_search.stub(:stats).and_return({:total_results => 4})
    @mock_search.stub(:status).and_return('pending')
    @mock_search.stub(:authorities).and_return([{:full_name => "Foo"}])

    HampshireSearch.should_receive(:new).and_return(@mock_search)
    @mock_search.stub(:perform_search).and_return(mock_results)

    visit search_applications_url(:host => 'hampshire.127.0.0.1.xip.io:3000', :results => true, :location => 'GU14 7ST', :display => 'list', :status => 'pending')
    expect(page).to have_no_selector('div#sidebar-stats')
  end

  # assumes that there are 100 - or fewer - items per page
  scenario "102 matching results with no matching MapIt authority (as a list)" do
    mock_results = mock_search_results(102)
    @mock_search.stub(:stats).and_return({:total_results => 102})

    HampshireSearch.should_receive(:new).and_return(@mock_search)
    @mock_search.stub(:perform_search).and_return(mock_results)

    visit search_applications_url(:host => 'hampshire.127.0.0.1.xip.io:3000', :results => true, :status => 'all', :location => 'GU14 7ST', :display => 'list')
    expect(page).to have_content('Show results on a map')
    expect(page).to have_content("Found 102 matching planning applications")
    expect(page).to have_no_content('See more statistics for')
    expect(page).to have_selector('div#sidebar-stats')
    expect(page).to have_selector('div.pagination')
  end

  scenario "more than 1000 matching results" do
    mock_results = mock_search_results(1)
    @mock_search.stub(:stats).and_return({:total_results => 1002})

    HampshireSearch.should_receive(:new).and_return(@mock_search)
    @mock_search.stub(:perform_search).and_return(mock_results)

    visit search_applications_url(:host => 'hampshire.127.0.0.1.xip.io:3000', :results => true, :status => 'all', :location => 'GU14 7ST', :display => 'list')
    expect(page.text).to include("Found more than\n1,000\nmatching planning applications")
  end
end
