class CreatePayments < ActiveRecord::Migration
  def change
    create_table :payments do |t|
      t.string :payment_id
      t.integer :user_id
      t.float :amount

      t.timestamps null: false
    end
  end
end
