class AddImageCountToTemplates < ActiveRecord::Migration
  def change
  	add_column :templates, :image_count, :integer
  end
end
