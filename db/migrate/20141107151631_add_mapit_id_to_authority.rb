# Hampshire authority tweak
class AddMapitIdToAuthority < ActiveRecord::Migration
  def change
    add_column :authorities, :mapit_id, :integer
  end
end