class AddPageIdToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :page_id, :string
  end
end
