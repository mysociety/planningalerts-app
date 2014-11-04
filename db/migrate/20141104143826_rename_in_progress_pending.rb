# Hampshire stats tables
class RenameInProgressPending < ActiveRecord::Migration
  def change
    rename_column :authority_stats_summaries, :in_progress, :pending
  end
end