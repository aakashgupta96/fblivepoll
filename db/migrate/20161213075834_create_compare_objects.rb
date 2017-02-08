class CreateCompareObjects < ActiveRecord::Migration
  def change
    create_table :compare_objects do |t|
      t.string :name
      t.integer :type
     
      t.timestamps null: false
    end
  end
end
