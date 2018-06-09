class AddFanCountToBigPage < ActiveRecord::Migration
  def change
    add_column :big_pages, :fan_count, :integer, default: 0
  end
end
