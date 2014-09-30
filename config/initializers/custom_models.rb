custom_path = MySociety::Config::get('CUSTOM_MODELS_PATH', false)
if custom_path
  require File.expand_path "../../../#{custom_path}/model_patches.rb", __FILE__
end