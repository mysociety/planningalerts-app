require File.expand_path(File.join(File.dirname(__FILE__),'..','spec_helper.rb'))

describe Configuration do
  # assumes that config/general.yml and config/test.yml exist
  it "should have copied values in from test.yml" do
    Configuration::COUNTRY_NAME.should eq 'the UK'
  end

  it "should automatically supply values from test.yml not found in the model" do
    Configuration::JUST_HERE_FOR_THE_TEST.should eq true
  end

  it "should still raise a NameError when asked for an undefined constant" do
    expect{Configuration::MADE_UP_CONSTANT}.to raise_error(NameError)
  end
end