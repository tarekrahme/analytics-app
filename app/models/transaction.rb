# == Schema Information
#
# Table name: transactions
#
#  id                  :bigint           not null, primary key
#  shopify_app_id      :bigint           not null
#  provider_id         :string
#  interval            :string
#  gross_amount        :decimal(10, 2)
#  net_amount          :decimal(10, 2)
#  shopify_fee         :decimal(10, 2)
#  provider_created_at :datetime
#  shop_id             :bigint           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  transaction_type    :string
#
# Indexes
#
#  index_transactions_on_provider_id              (provider_id) UNIQUE
#  index_transactions_on_shop_id                  (shop_id)
#  index_transactions_on_shop_id_and_provider_id  (shop_id,provider_id) UNIQUE
#  index_transactions_on_shopify_app_id           (shopify_app_id)
#
class Transaction < ApplicationRecord
  belongs_to :shopify_app
  belongs_to :shop

  scope :payments, -> { where.not(transaction_type: "APP_SALE_ADJUSTMENT") }
  scope :monthly, -> { where.not(interval: "ANNUAL") }
  after_save :calculate_shop_earnings_and_payments

  def calculate_shop_earnings_and_payments
    shop.update(total_earnings: shop.calculate_total_earnings,
                total_number_of_payments: shop.calculate_total_number_of_payments,
                average_payment: shop.calculate_average_payment)

    shop.update(monthly_subscription: net_amount, gross_monthly_subscription: gross_amount) if transaction_type == "APP_SUBSCRIPTION_SALE"
  end
end
