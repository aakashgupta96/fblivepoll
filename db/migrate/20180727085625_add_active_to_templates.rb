class AddActiveToTemplates < ActiveRecord::Migration
  def change
    add_column :templates, :active, :boolean, default: true
  end
end
