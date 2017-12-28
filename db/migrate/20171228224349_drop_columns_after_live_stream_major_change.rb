class DropColumnsAfterLiveStreamMajorChange < ActiveRecord::Migration
  def change
  	remove_column :posts, :key
  	remove_column :posts, :video_id
  	remove_column :posts, :page_id
  	remove_column :posts, :live_id
  	remove_column :posts, :process_id
  	remove_column :shared_posts, :post_id
  end
end
