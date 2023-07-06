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
class Transaction < ApplicationRecord
  belongs_to :shopify_app
  belongs_to :shop
end
