class ChangeColumnName < ActiveRecord::Migration
  def change
  	rename_column :posts, :background_image, :background
  end
end
