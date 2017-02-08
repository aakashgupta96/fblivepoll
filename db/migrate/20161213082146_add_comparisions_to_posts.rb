class AddComparisionsToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :comparisions, :integer
  end
end
