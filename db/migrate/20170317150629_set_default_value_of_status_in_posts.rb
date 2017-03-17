class SetDefaultValueOfStatusInPosts < ActiveRecord::Migration
  def change
  	change_column :posts, :status, :string, :default => "drafted"
  end
end
