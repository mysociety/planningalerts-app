require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper.rb'))

feature "Hampshire theme home page" do
  context "in general" do
    scenario "Visiting the home page" do
      VCR.use_cassette('hampshire_theme_homepage', :record => :once, :allow_playback_repeats => true) do
        visit root_url(:host => "hampshire.127.0.0.1.xip.io:3000")
      end
      expect(page).to have_field("Show applications for", :with => 'anything')
      expect(page).to have_field("location")
      expect(page).to have_content("Explore planning applications")
    end
  end

  context "search validation" do
    scenario "Submitting an valid looking invalid postcode" do
      VCR.use_cassette('hampshire_theme_valid_looking_invalid_postcode', :record => :once, :allow_playback_repeats => true) do
        visit root_url(:host => "hampshire.127.0.0.1.xip.io:3000")
        fill_in("location", :with => "SW99 0AA")
        click_button("Search")
      end
      expect(page).to have_content("Sorry, it doesn't look like that's a valid postcode.")
    end

    scenario "Submitting an invalid postcode" do
      VCR.use_cassette('hampshire_theme_invalid_postcode', :record => :once, :allow_playback_repeats => true) do
        visit root_url(:host => "hampshire.127.0.0.1.xip.io:3000")
        fill_in("location", :with => "SO234B")
        click_button("Search")
      end
      expect(page).to have_content("Sorry, we couldn't find that address.")
    end

    scenario "Submitting an invalid address" do
      VCR.use_cassette('hampshire_theme_invalid_address', :record => :once, :allow_playback_repeats => true) do
        visit root_url(:host => "hampshire.127.0.0.1.xip.io:3000")
        fill_in("location", :with => "alas, poor yorick")
        click_button("Search")
      end
      expect(page).to have_content("Sorry, we couldn't find that address.")
    end
  end
end