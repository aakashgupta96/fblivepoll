class AddFreeVideosLeftToUsers < ActiveRecord::Migration
  def change
    add_column :users, :free_videos_left, :integer,  default: 5
  end
end
