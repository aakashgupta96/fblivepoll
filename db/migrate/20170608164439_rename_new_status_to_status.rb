class RenameNewStatusToStatus < ActiveRecord::Migration
  def change
  	rename_column :posts, :new_status, :status
  end
end
