class AddPositionXPostionYHeightWidthToImages < ActiveRecord::Migration
  def change
  	add_column :images, :position_x, :integer
  	add_column :images, :position_y, :integer
  	add_column :images, :height, :integer
  	add_column :images, :width, :integer
  end
end
