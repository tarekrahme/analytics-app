class PopulateActivatedOnColumnJob < ApplicationJob
  queue_as :default

  def perform(app_id:, since:)
    app = ShopifyApp.find(app_id)
    shops = app.shops.joins(:events).where('events.occured_at >= ?', since).distinct

    shops.find_each do |shop|
      shop.determine_status
    end
  end
end