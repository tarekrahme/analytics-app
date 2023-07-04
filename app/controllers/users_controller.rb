class UsersController < ApplicationController
  def update
    user = User.find(params[:id])
    user.update(user_params)

    RetreiveDataJob.perform_later(user_id: user.id)
    flash[:notice] = "Great! Retreiving your data now, please give it a few seconds."
    redirect_to root_path
  end

  private

  def user_params
    params.require(:user).permit(:access_token, :organisation_provider_id)
  end
end