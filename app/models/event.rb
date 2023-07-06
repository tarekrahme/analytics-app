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
class Event < ApplicationRecord
  belongs_to :shopify_app
  belongs_to :shop
end
