require 'spec_helper'

feature "Custom Hampshire pages" do
  scenario "Visiting the home page within the Hampshire theme" do
    VCR.use_cassette('planningalerts') do
      visit address_applications_url(:host => "hampshire.127.0.0.1.xip.io:3000")
    end

    page.should have_content("Search for and compare the outcomes of planning applications in Hampshire.")
    page.should have_content("Enter a postcode or address")
    page.should have_content("or locate me automatically")
  end
end
