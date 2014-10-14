class AddCategoryToApplication < ActiveRecord::Migration
  def change
    add_column :applications, :category, :string
  end
end
