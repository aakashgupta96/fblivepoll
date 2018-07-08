class CreateExtraTexts < ActiveRecord::Migration
  def change
    create_table :extra_texts do |t|
      t.string :text
      t.integer :font_size
      t.string :color
      t.integer :position_x
      t.integer :position_y
      t.integer :post_id

      t.timestamps null: false
    end
  end
end
