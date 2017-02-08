class AddImageToCompareObjects < ActiveRecord::Migration
  def change
    add_column :compare_objects, :image, :string
  end
end
