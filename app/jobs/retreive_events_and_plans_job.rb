class RetreiveEventsAndPlansJob < ApplicationJob
  queue_as :default

  def perform(app_id:, since: nil)
    app = ShopifyApp.find(app_id)
    app.retreive_events_and_plans(since: since)
  end
end