# == Schema Information
#
# Table name: plans
#
#  id             :bigint           not null, primary key
#  amount         :decimal(10, 2)
#  shopify_app_id :bigint           not null
#  name           :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_plans_on_shopify_app_id             (shopify_app_id)
#  index_plans_on_shopify_app_id_and_amount  (shopify_app_id,amount) UNIQUE
#
class Plan < ApplicationRecord
  belongs_to :shopify_app
end
