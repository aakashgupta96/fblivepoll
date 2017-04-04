class AddHasneedsBackgroundAndNeedsImageNamesToTemplates < ActiveRecord::Migration
  def change
    add_column :templates, :needs_backgroound, :boolean, default: false
    add_column :templates, :needs_image_names, :boolean, default: false
  end
end
