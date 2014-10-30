# Hampshire classification field
class AddCouncilCategoryToApplication < ActiveRecord::Migration
  def change
    add_column :applications, :council_category, :string
  end
end
