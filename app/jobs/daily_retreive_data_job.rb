class DailyRetreiveDataJob < ApplicationJob
  queue_as :default

  def perform(user_id: nil)
    if user_id
      users = [User.find(user_id)]
    else
      users = User.where(plan: 1)
    end

    users.each do |user|
      user.retreive_data(since: 3.days.ago.strftime("%Y-%m-%dT%H:%M:%S%z"))
    end
  end
end