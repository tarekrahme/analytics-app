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
class Plan < ApplicationRecord
  belongs_to :shopify_app
end
