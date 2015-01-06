require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper.rb'))

feature "Hampshire individual authority page" do
  def stub_stats(overview=nil)
    stats = mock_model(AuthorityStatsSummary)
    unless overview
      overview = {:total => 1234, :percentage_approved => 80, :percentage_delayed => 5}
    end
    stats.stub(:overview).and_return(mock(overview))
    stats.stub(:overview_json).and_return(overview)
    stats
  end

  scenario "it should have a section to select an authority from a dropdown list" do
    authority1 = mock_model(Authority, :full_name => "Test authority 1", :short_name_encoded => "test1", :applications => [])
    authority2 = mock_model(Authority, :full_name => "Test authority 2", :short_name_encoded => "test2", :applications => [])
    Authority.stub(:enabled).and_return([authority1, authority2])
    Authority.stub(:find_by_short_name_encoded!).with("test1").and_return(authority1)

    visit authority_url(:id => "test1", :host => "hampshire.127.0.0.1.xip.io:3000")

    expect(page).to have_content("Showing all applications for")
    expect(page).to have_selector("form#switch-authority.container")
    expect(page).to have_selector("option", text: "Test authority 1")
    expect(page).to have_selector("option", text: "Test authority 2")
  end

  scenario "should list all the applications for the authority" do
    authority = Factory(:authority, :full_name => "Foo", :email => "feedback@foo.gov.au")
    applications = FactoryGirl.build_list(:application, 4, council_reference: "ref", authority: authority, status: 'approved', id: 1)
    authority.stub(:applications).and_return(applications)
    Authority.stub(:enabled).and_return([authority])
    authority.stub(:stats).and_return(stub_stats)
    authority.stub(:median_applications_received_per_week).and_return(12)
    Authority.stub(:find_by_short_name_encoded!).with("test").and_return(authority)

    visit authority_url(:id => "test", :host => "hampshire.127.0.0.1.xip.io:3000")

    # should show the results
    expect(page).to have_no_selector("p.no-results")
    expect(page).to have_selector("article.application")

    # should show the sidebar
    expect(page).to have_selector("div#sidebar")
    expect(page.text).to include("Showing all\n4\nplanning applications made to\nFoo")
    # ...with stats
    expect(page).to have_selector("div#sidebar-stats")
    # ...and a summary
    expect(page.text).to include("Foo receives on average 12 applications per week")
    expect(page.text).not_to include("5% of applications were delayed.")
  end

  scenario "should display a message when there are no applications to show" do
    authority = Factory(:authority, :full_name => "Foo", :email => "feedback@foo.gov.au")
    authority.stub(:applications).and_return([])
    Authority.stub(:enabled).and_return([authority])
    #authority.stub(:stats).and_return(stub_stats)
    authority.stub(:median_applications_received_per_week).and_return(0)
    Authority.stub(:find_by_short_name_encoded!).with("test").and_return(authority)

    visit authority_url(:id => "test", :host => "hampshire.127.0.0.1.xip.io:3000")

    # should show the no results message
    expect(page).to have_selector("p.no-results")
    expect(page).to have_content("Sorry, no applications for Foo have been collected yet.")

    # should not attempt to list articles
    expect(page).to have_no_selector("article.application")

    # should show the sidebar
    expect(page).to have_selector("div#sidebar")
    expect(page.text).to include("Showing all\n0\nplanning applications made to\nFoo")
    # ...without stats
    expect(page).to have_no_selector("div#sidebar-stats")
    # ...or a summary
    expect(page.text).not_to include("applications per week")
  end
end
