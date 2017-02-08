class AddCounterColorToPost < ActiveRecord::Migration
  def change
    add_column :posts, :counter_color, :string
  end
end
