# load this file into any Controller you want to be able to override in a theme
# then paste (and uncomment) the following 2 lines inside the Controller class:
#
#  include ThemeControllerActions
#  before_filter :use_theme_controller_actions

module ThemeControllerActions
  protected

  def use_theme_controller_actions
    # by definition, the default theme shouldn't override anything
    return if @themer.class.to_s == "DefaultTheme"

    current_class_name = self.class.to_s
    action = params[:action]

    if eval("#{@themer.class}::#{current_class_name}").public_method_defined?(:overrides_base_theme?) and
       eval("#{@themer.class}::#{current_class_name}").public_method_defined?(action.to_sym)
      theme_controller = eval("#{@themer.class}::#{current_class_name}").new(self)
      result = theme_controller.send(action.to_sym)

      # not ideal but... copy back any view assigned variables
      # set by the theme controller
      theme_controller.view_assigns.each do |key, value|
        instance_variable_set("@#{key}", value)
      end

      # force a render of the default view to prevent the execution
      # of the default controller method if false is returned by the
      # theme method
      if result == false
        render action
      end
    end
  end
end