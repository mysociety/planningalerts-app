# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require 'rake'

if ARGV.include?("spec")
  ENV["RAILS_ENV"] = "test"
end

require File.expand_path('../config/application', __FILE__)

PlanningalertsApp::Application.load_tasks

