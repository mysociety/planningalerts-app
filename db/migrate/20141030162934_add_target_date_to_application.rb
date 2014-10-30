# Hampshire stats field
class AddTargetDateToApplication < ActiveRecord::Migration
  def change
    add_column :applications, :target_date, :date
  end
end
