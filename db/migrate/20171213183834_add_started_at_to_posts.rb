class AddStartedAtToPosts < ActiveRecord::Migration
  def change
  	add_column :posts, :started_at, :datetime
  end
end
