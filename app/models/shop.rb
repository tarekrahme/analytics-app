# == Schema Information
#
# Table name: shops
#
#  id                       :bigint           not null, primary key
#  shopify_app_id           :bigint           not null
#  user_id                  :bigint           not null
#  shopify_domain           :string
#  provider_id              :string
#  name                     :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  activated_on             :datetime
#  total_earnings           :decimal(10, 2)   default(0.0)
#  total_number_of_payments :integer          default(0)
#  average_payment          :decimal(10, 2)   default(0.0)
#
class Shop < ApplicationRecord
  belongs_to :shopify_app
  belongs_to :user

  has_many :transactions, -> { order('provider_created_at ASC') }, dependent: :destroy
  has_many :events, -> { order('events.occured_at ASC') }, dependent: :destroy

  scope :customer, -> { where.not(total_number_of_payments: 0) }

  def display_name
    name.size > 24 ? name.first(20) + '...' : name
  end

  def calculate_total_earnings
    transactions.sum(:net_amount)
  end

  def calculate_total_number_of_payments
    transactions.payments.count
  end

  def calculate_average_payment
    (calculate_total_earnings / calculate_total_number_of_payments).round(2)
  end
end
