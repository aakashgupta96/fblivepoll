class CreateFbPages < ActiveRecord::Migration
  def change
    create_table :fb_pages do |t|
      t.string :page_id, unique: true
      t.integer :status, default: 0
      t.integer :fan_count
      t.string :image_url
      t.string :name

      t.timestamps null: false
    end
  end
end
