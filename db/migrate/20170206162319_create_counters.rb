class CreateCounters < ActiveRecord::Migration
  def change
    create_table :counters do |t|
      t.string :reaction
      t.integer :x
      t.integer :y

      t.timestamps null: false
    end
  end
end
