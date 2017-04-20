class TypoErrorFix < ActiveRecord::Migration
  def change
  	rename_column :templates, :needs_backgroound, :needs_background
  end
end
