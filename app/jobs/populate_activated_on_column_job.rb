class PopulateActivatedOnColumnJob < ApplicationJob
  queue_as :default

  def perform(app_id:)
    app = ShopifyApp.find(app_id)
    shops = app.shops

    shops.find_each do |shop|
      shop.update!(activated_on: shop.events.order(:occured_at).first.occured_at)
    end
  end
end