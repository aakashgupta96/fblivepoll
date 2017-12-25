class CreatePages < ActiveRecord::Migration
  def change
    create_table :pages,id: false do |t|
      t.string :page_id, null: false, unique: true

      t.timestamps null: false
    end

    add_index :pages, :page_id, unique: true
  end
end
