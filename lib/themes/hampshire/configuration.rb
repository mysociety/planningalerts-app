Rails.configuration.to_prepare do
  module Configuration
    self.constants.each do |const|
      # unset the constant
      remove_const(const)

      # reset, copying the value from the yml file
      const_set(const.to_s, MySociety::Config::get("#{const.to_s}"))
    end

    def self.const_missing(const)
      if MySociety::Config::get("#{const.to_s}", "NotDefined") != "NotDefined"
        const_set(const.to_s, MySociety::Config::get("#{const.to_s}"))
      else
        raise NameError, "uninitialized constant #{const}"
      end
    end
  end
end