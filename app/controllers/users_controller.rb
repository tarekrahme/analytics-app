class UsersController < ApplicationController
  def update
    user = User.find(params[:id])
    user.update(user_params)

    RetreiveDataJob.perform_later(user_id: user.id)
    flash[:notice] = "Great! Retreiving your data now, please give it a 5 minutes if you have small app or up to 30 minutes if you have a large app/apps" 
    redirect_to root_path
  end

  def trigger
    user = User.find(params[:id])
    RetreiveDataJob.perform_later(user_id: user.id)
    flash[:notice] = "Great! Retreiving your data now, please give it a few minutes."
    redirect_to root_path
  end

  private

  def user_params
    params.require(:user).permit(:access_token, :organisation_provider_id)
  end
end