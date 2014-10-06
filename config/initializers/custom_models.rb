# override the Configuration object with the MySociety library
# if general.yml and test.yml exist in the config folder
if File.exists?(File.expand_path("../../general.yml", __FILE__)) and File.exists?(File.expand_path("../../test.yml", __FILE__))
  require File.expand_path "../../../lib/themes/hampshire/configuration.rb", __FILE__
end

# load theme customisations if there is CUSTOM_MODELS_PATH is set
if defined?(Configuration::CUSTOM_MODELS_PATH)
  custom_path = Configuration::CUSTOM_MODELS_PATH
end
if custom_path
  require File.expand_path "../../../#{custom_path}/model_patches.rb", __FILE__
end