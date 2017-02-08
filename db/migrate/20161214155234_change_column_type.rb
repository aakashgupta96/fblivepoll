class ChangeColumnType < ActiveRecord::Migration
  def change
  	change_column :compare_objects, :emoticon,  :string
  end
end
