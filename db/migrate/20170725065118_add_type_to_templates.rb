class AddTypeToTemplates < ActiveRecord::Migration
  def change
    add_column :templates, :category, :integer, default: 0
  end
end
