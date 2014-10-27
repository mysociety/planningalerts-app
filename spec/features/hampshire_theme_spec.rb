require 'spec_helper'

feature "Custom Hampshire pages" do
  scenario "Visiting the home page within the Hampshire theme" do
    VCR.use_cassette('hampshire_theme_homepage', :record => :once) do
      visit search_applications_url(:host => "hampshire.127.0.0.1.xip.io:3000")
    end

    page.should have_content("Search for and compare the outcomes of planning applications in Hampshire.")
    page.should have_field("Show applications for", :with => 'anything')
    page.should have_field("Located around")
    page.should have_content("or locate me automatically")
  end

  scenario "Submitting an valid looking invalid postcode" do
    VCR.use_cassette('hampshire_theme_valid_looking_invalid_postcode', :record => :new_episodes) do
      visit search_applications_url(:host => "hampshire.127.0.0.1.xip.io:3000")
      fill_in("Located around:", :with => "SW99 0AA")
      click_button("Search")
    end

    page.should have_content("Sorry, it doesn't look like that's a valid postcode.")
  end

  scenario "Submitting an invalid postcode" do
    VCR.use_cassette('hampshire_theme_invalid_postcode', :record => :new_episodes) do
      visit search_applications_url(:host => "hampshire.127.0.0.1.xip.io:3000")
      fill_in("Located around:", :with => "SO234B")
      click_button("Search")
    end

    page.should have_content("Sorry, we couldn't find that address.")
  end

  scenario "Submitting an invalid address" do
    VCR.use_cassette('hampshire_theme_invalid_address', :record => :new_episodes) do
      visit search_applications_url(:host => "hampshire.127.0.0.1.xip.io:3000")
      fill_in("Located around:", :with => "alas, poor yorick")
      click_button("Search")
    end

    page.should have_content("Sorry, we couldn't find that address.")
  end
end
