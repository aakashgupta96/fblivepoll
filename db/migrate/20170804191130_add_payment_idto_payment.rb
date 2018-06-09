class AddPaymentIdtoPayment < ActiveRecord::Migration
  def change
  	add_column :payments, :payment_id, :string, null: false, unique: true
  end
end
