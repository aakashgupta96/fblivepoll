class ChangeComparisionsToComparison < ActiveRecord::Migration
  def change
  	rename_column :posts, :comparisions, :comparisons
  end
end
