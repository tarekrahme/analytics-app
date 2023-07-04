class HomeController < ApplicationController
  def index
    @user = current_user

    @access_token = @user.access_token
    @organisation_provider_id = @user.organisation_provider_id
  end
end