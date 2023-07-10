# == Schema Information
#
# Table name: events
#
#  id             :bigint           not null, primary key
#  shopify_app_id :bigint           not null
#  occured_at     :datetime
#  event_type     :string
#  shop_id        :bigint           not null
#  gross_amount   :decimal(10, 2)
#  billing_on     :date
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_events_on_app_and_shop_and_event_type_and_occured_at  (shopify_app_id,shop_id,event_type,occured_at) UNIQUE
#  index_events_on_shop_id                                     (shop_id)
#  index_events_on_shopify_app_id                              (shopify_app_id)
#
class Event < ApplicationRecord
  belongs_to :shopify_app
  belongs_to :shop

  scope :activated, -> { where(event_type: 'SUBSCRIPTION_CHARGE_ACTIVATED') }
  scope :cancelled, -> { where(event_type: 'SUBSCRIPTION_CHARGE_CANCELED') }

  def activated?
    event_type == 'SUBSCRIPTION_CHARGE_ACTIVATED'
  end

  def cancelled?
    event_type == 'SUBSCRIPTION_CHARGE_CANCELED'
  end

  def frozen?
    event_type == 'SUBSCRIPTION_CHARGE_FROZEN'
  end
end
