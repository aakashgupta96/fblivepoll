class RenameTableAdminToModerator < ActiveRecord::Migration
  def change
  	rename_table :admins, :moderators
  end
end
