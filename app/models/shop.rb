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
#  churned_on               :datetime
#  monthly_subscription     :decimal(10, 2)
#
class Shop < ApplicationRecord
  belongs_to :shopify_app
  belongs_to :user

  has_many :transactions, -> { order('provider_created_at ASC') }, dependent: :destroy
  has_many :events, -> { order('events.occured_at ASC') }, dependent: :destroy

  scope :once_customer, -> { where.not(activated_on: nil) }
  scope :once_mrr_customer, -> { where.not(total_number_of_payments: 0) }
  scope :current_customer, -> { where.not(activated_on: nil).where(churned_on: nil) }
  scope :customer_on_date, ->(date) { where('activated_on <= ?', date).where('churned_on >= ? OR churned_on IS NULL', date) }
  scope :new_customer_during_month, ->(date) { where(activated_on: date.beginning_of_month..(date+1.month).beginning_of_month) }

  scope :active, -> { where(churned_on: nil) }
  scope :churned, -> { where.not(churned_on: nil) }
  scope :churned_during_month, ->(date) { churned.where(churned_on: date.beginning_of_month..(date+1.month).beginning_of_month) }
  scope :churned_since, ->(date) { churned.where('churned_on >= ?', date) }

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

  def determine_status
    # check if the shop has activated a subscription
    if events.activated.any?
      update(activated_on: events.activated.first.occured_at)
    end

    # check if the shop has cancelled a subscription
    if events.cancelled.any?
      last_two_events = events.last(2)
      first_event = last_two_events.first
      second_event = last_two_events.second

      time_difference_between_events = first_event.occured_at - second_event.occured_at

      if time_difference_between_events * -1 > 2.seconds
        if second_event.cancelled?
          update!(churned_on: second_event.occured_at)
        elsif second_event.activated?
          update!(churned_on: nil)
        end
      else
        if first_event.activated? || second_event.activated?
          update!(churned_on: nil)
        end
      end
    else
      update!(churned_on: nil)
    end

    if events.last.frozen?
      update(churned_on: events.last.occured_at)
    end
  end
end
