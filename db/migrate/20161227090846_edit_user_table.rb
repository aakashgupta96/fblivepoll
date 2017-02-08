class EditUserTable < ActiveRecord::Migration
  def change
  	remove_column :users, :reset_password_token
  	remove_column :users, :reset_password_sent_at
  	remove_column :users, :remember_created_at
  	remove_column :users, :sign_in_count
  end
end
