class RetreiveDataJob < ApplicationJob
  queue_as :default

  def perform(user_id:)
    user = User.find(user_id)
    user.retreive_data
  end
end