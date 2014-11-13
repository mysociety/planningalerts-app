require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper.rb'))

feature "Hampshire authority list page" do
  scenario "it should not have list of states/counties" do
    visit authorities_url(:host => "hampshire.127.0.0.1.xip.io:3000")
    expect(page).to have_no_content('Go to state')
  end

  scenario "authorities with applications should have a stats overview" do
    application = mock_model(Application)
    authority = mock_model(Authority, :full_name => "Test authority", :short_name_encoded => "test")
    stats = mock_model(AuthorityStatsSummary)
    stats.stub(:overview).and_return(mock({:total => 1234, :percentage_approved => 80, :percentage_delayed => 5}))
    authority.stub(:stats).and_return(stats)
    Authority.stub(:enabled).and_return([authority])

    visit authorities_url(:host => "hampshire.127.0.0.1.xip.io:3000")
    expect(page).to have_content("Test authority")
    expect(page).to have_content("1234 applications")
    expect(page).to have_content("80% approved")
    expect(page).to have_content("5% delayed")
  end

  scenario "authorites without applictions should not have a stats overview" do
    authority = mock_model(Authority, :full_name => "Test authority", :short_name_encoded => "test")
    stats = mock("stats")
    stats.stub(:overview).and_return(nil)
    authority.stub(:stats).and_return(stats)
    Authority.stub(:enabled).and_return([authority])

    visit authorities_url(:host => "hampshire.127.0.0.1.xip.io:3000")
    expect(page).to have_content("Test authority")
    expect(page).to have_no_content("% approved")
    expect(page).to have_no_content("% delayed")
  end
end