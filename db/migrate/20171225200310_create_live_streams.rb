class CreateLiveStreams < ActiveRecord::Migration
  def change
    create_table :live_streams do |t|
      t.string :page_id
      t.integer :post_id
      t.string :key
      t.string :video_id
      t.string :live_id
      t.integer :status, default: 0, null: false

      t.timestamps null: false
    end
  end
end
