class AddGrossMonthlySubscriptionToShops < ActiveRecord::Migration[7.0]
  def change
    add_column :shops, :gross_monthly_subscription, :decimal, precision: 10, scale: 2
  end
end
