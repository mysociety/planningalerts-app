require 'spec_helper'

feature "Custom Hampshire pages" do
  scenario "Visiting the home page within the Hampshire theme" do
    VCR.use_cassette('hampshire_theme') do
      visit address_applications_url(:host => "hampshire.127.0.0.1.xip.io:3000")
    end

    page.should have_content("Search for and compare the outcomes of planning applications in Hampshire.")
    page.should have_content("Enter a postcode or address")
    page.should have_content("or locate me automatically")
  end

  scenario "Submitting an valid looking invalid postcode" do
    VCR.use_cassette('hampshire_theme') do
      visit address_applications_url(:host => "hampshire.127.0.0.1.xip.io:3000")
      fill_in("Enter a postcode or address:", :with => "SW99 0AA")
      click_button("Search")
    end

    page.should have_content("Postcode is not valid")
  end

  scenario "Submitting an invalid postcode" do
    VCR.use_cassette('hampshire_theme', :record => :new_episodes) do
      visit address_applications_url(:host => "hampshire.127.0.0.1.xip.io:3000")
      fill_in("Enter a postcode or address:", :with => "SO234B")
      click_button("Search")
    end

    page.should have_content("Address not found")
  end

  scenario "Submitting an invalid address" do
    VCR.use_cassette('hampshire_theme', :record => :new_episodes) do
      visit address_applications_url(:host => "hampshire.127.0.0.1.xip.io:3000")
      fill_in("Enter a postcode or address:", :with => "alas, poor yorick")
      click_button("Search")
    end

    page.should have_content("Address not found")
  end
end
