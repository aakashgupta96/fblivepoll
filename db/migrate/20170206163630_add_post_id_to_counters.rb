class AddPostIdToCounters < ActiveRecord::Migration
  def change
    add_column :counters, :post_id, :integer
  end
end
