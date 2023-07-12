class HomeController < ApplicationController
  def index
    @user = current_user

    @plan = @user.plan
    @access_token = @user.access_token
    @organisation_provider_id = @user.organisation_provider_id
    @apps = @user.shopify_apps
    @shops = @user.shops
    @transactions = @user.transactions
    @plans = @user.plans
    @events = @user.events

    if @plan == 1
      redirect_to transactions_path
    end
  end
end