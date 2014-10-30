# Hampshire stats tables
class CreateAuthorityStats < ActiveRecord::Migration
  def change
    create_table :authority_stats_summaries, :force => true do |t|
      t.integer :authority_id
      t.string  :category
      t.integer :total
      t.integer :approved
      t.integer :refused
      t.integer :in_progress
      t.integer :delayed
      t.timestamps
    end
  end
end