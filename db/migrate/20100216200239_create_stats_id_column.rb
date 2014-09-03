# removed backticks, changed INT(11) to INT for Postgres support

class CreateStatsIdColumn < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE stats ADD id INT NOT NULL"
    execute "UPDATE stats SET id = '1' WHERE key = 'applications_sent'"
    execute "UPDATE stats SET id = '2' WHERE key = 'emails_sent'"
    execute "ALTER TABLE stats DROP PRIMARY KEY"
    execute "ALTER TABLE stats ADD PRIMARY KEY (id)"
  end

  def self.down
    remove_column :stats, :column_name
    execute "ALTER TABLE stats DROP COLUMN id"
    execute "ALTER TABLE stats ADD PRIMARY KEY (key)"
  end
end