module Configuration
  if ENV["RAILS_ENV"] == "test"
    config = YAML::load_file(Rails.root + "config/test.yml")
  else
    config = YAML::load_file(Rails.root + "config/general.yml")
  end

  config.keys.each do |const|
    # unset the constant if already defined
    remove_const(const) if self.constants.include?(const.to_sym)

    # set the new value
    const_set(const.to_s, config[const])
  end
end