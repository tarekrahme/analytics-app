class AddInfoToShops < ActiveRecord::Migration[7.0]
  def change
    add_column :shops, :total_earnings, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :shops, :total_number_of_payments, :integer, default: 0
    add_column :shops, :average_payment, :decimal, precision: 10, scale: 2, default: 0.0
  end
end
