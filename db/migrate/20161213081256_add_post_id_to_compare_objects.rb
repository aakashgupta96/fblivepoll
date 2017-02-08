class AddPostIdToCompareObjects < ActiveRecord::Migration
  def change
    add_column :compare_objects, :post_id, :integer
  end
end
