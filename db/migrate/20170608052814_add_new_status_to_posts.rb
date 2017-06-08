class AddNewStatusToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :new_status, :integer, default: 0
  end
end
