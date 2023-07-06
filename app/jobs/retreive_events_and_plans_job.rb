class RetreiveEventsAndPlansJob < ApplicationJob
  queue_as :default

  def perform(app_id:)
    app = ShopifyApp.find(app_id)
    app.retreive_events_and_plans
  end
end