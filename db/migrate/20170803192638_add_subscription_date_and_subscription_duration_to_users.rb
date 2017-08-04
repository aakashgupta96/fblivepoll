class AddSubscriptionDateAndSubscriptionDurationToUsers < ActiveRecord::Migration
  def change
    add_column :users, :subscription_date, :date
    add_column :users, :subscription_duration, :integer
  end
end
