class HampshireTheme
  class ControllerBase < ::ApplicationController
    def initialize(original_controller)
      self.response = original_controller.response
      self.params = original_controller.params
      self.request = original_controller.request
      self.prepend_view_path original_controller.view_paths.paths[0]
      self.lookup_context.prefixes = original_controller.lookup_context.prefixes
      original_controller.view_assigns.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end
  end
end