require 'spec_helper'

describe ThemeChooser do

  it "should use the configured theme first" do
    # TODO - clearly a code smell, the config object should be passed into
    # the ThemeChooser so that we can make a double and pass that in instead
    # but that should probably happen when we make the config object more
    # generic
    MySociety::Config.stub(:get).with('THEME').and_return('default')
    MySociety::Config.stub(:get).with('THEME', false).and_return('default')
    request = double('request')
    # No theme should be called to check against the request domain
    request.should_not_receive(:domain)
    expect(ThemeChooser.themer_from_request(request).class).to eq(DefaultTheme)
  end

  it "should work if there's no THEME config variable set" do
    # THEME is set to nil in test.yml
    request = double('request')
    # test.domain shouldn't match any of the existing themes, so it will fall
    # through to the default theme
    request.should_receive(:domain).at_least(:once).and_return("test.domain")
    expect(ThemeChooser.themer_from_request(request).class).to eq(DefaultTheme)
  end
end