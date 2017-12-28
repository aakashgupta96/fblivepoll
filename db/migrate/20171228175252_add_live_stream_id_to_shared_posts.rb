class AddLiveStreamIdToSharedPosts < ActiveRecord::Migration
  def change
    add_column :shared_posts, :live_stream_id, :integer
  end
end
