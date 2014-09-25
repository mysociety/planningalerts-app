class HampshireTheme
  class ControllerBase < ::ApplicationController
    def initialize(object)
      self.response = object.response
      self.params = object.params
      self.request = object.request
      self.prepend_view_path object.view_paths.paths[0]
      self.lookup_context.prefixes = object.lookup_context.prefixes
    end
  end
end