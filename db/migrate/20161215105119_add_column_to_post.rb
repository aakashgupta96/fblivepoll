class AddColumnToPost < ActiveRecord::Migration
  def change
  	add_column :posts, :fb_id, :string
  end
end
