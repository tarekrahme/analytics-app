class AddMonthlySubscriptionToShops < ActiveRecord::Migration[7.0]
  def change
    add_column :shops, :monthly_subscription, :decimal, precision: 10, scale: 2
  end
end
