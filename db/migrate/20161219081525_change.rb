class Change < ActiveRecord::Migration
  def change
  	rename_column :posts, :fb_id, :video_id
  	remove_column :posts, :page_id
  end
end