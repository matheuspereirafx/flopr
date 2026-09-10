class ProfilesController < ApplicationController
  skip_before_action :ensure_profile_completed!

  def edit
    redirect_to after_sign_in_path_for(current_user) unless current_user.profile_incomplete?
  end

  def update
    current_user.assign_attributes(profile_params.merge(profile_completed_at: Time.current))

    if current_user.save
      redirect_to after_sign_in_path_for(current_user), notice: "Perfil concluído com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:name, :username)
  end
end
