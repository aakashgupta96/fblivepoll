class DropBigPageTable < ActiveRecord::Migration
  def change
  	drop_table :big_pages
  end
end
