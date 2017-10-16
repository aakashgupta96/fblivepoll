class CreateBigPages < ActiveRecord::Migration
  def change
    create_table :big_pages do |t|
      t.string :name
      t.string :page_id
      t.string :image_url

      t.timestamps null: false
    end
  end
end
