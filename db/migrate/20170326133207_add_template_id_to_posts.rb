class AddTemplateIdToPosts < ActiveRecord::Migration
  def change
  	add_column :posts, :template_id, :integer
  end
end
