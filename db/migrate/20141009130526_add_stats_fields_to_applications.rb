# for Hampshire stats requirements
class AddStatsFieldsToApplications < ActiveRecord::Migration
  def change
    add_column :applications, :status, :string
    add_column :applications, :delayed, :boolean
    add_column :applications, :decision_date, :date
  end
end