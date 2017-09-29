class CreateVideos < ActiveRecord::Migration
  def change
    create_table :videos do |t|
      t.string :file
      t.integer :post_id

      t.timestamps null: false
    end
  end
end
