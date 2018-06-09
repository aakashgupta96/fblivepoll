class AddStatusToPayments < ActiveRecord::Migration
  def change
  	add_column :payments, :status, :integer, default: 0 
  end
end
