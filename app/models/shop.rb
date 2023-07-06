# == Schema Information
#
# Table name: shops
#
#  id             :bigint           not null, primary key
#  shopify_app_id :bigint           not null
#  user_id        :bigint           not null
#  shopify_domain :string
#  provider_id    :string
#  name           :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class Shop < ApplicationRecord
  belongs_to :shopify_app
  belongs_to :user

  has_many :transactions, dependent: :destroy
  has_many :events, -> { order('events.occured_at ASC') }, dependent: :destroy
end
