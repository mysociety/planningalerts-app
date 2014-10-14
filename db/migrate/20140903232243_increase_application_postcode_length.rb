# to accommodate UK postcode format
class IncreaseApplicationPostcodeLength < ActiveRecord::Migration
  def change
    change_column :applications, :postcode, :string, :limit => 10
  end
end