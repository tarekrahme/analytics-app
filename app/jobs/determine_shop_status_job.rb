class DetermineShopStatusJob < ApplicationJob
  queue_as :default

  def perform(shop_id:)
    shop = Shop.find(shop_id)
    shop.determine_status
  end
end