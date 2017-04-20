class AddLiveIdToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :live_id, :string
  end
end
