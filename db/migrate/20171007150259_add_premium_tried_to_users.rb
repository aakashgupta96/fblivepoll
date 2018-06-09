class AddPremiumTriedToUsers < ActiveRecord::Migration
  def change
    add_column :users, :premium_tried, :boolean, default: false
  end
end
