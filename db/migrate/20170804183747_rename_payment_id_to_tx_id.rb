class RenamePaymentIdToTxId < ActiveRecord::Migration
  def change
  	rename_column :payments, :payment_id, :tx_id
  	change_column :payments, :tx_id, :string, null: false, unique: true
  end
end
