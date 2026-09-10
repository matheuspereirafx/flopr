class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :ensure_profile_completed!, unless: :devise_controller?
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(
      :sign_up,
      keys: %i[terms username name]
    )
  end

  def after_sign_in_path_for(resource)
    return onboarding_profile_path if resource.profile_incomplete?

    case params[:role]
    when "player"
      player_tournaments_path
    when "organizer"
      clubs_path
    else
      super
    end
  end

  def ensure_profile_completed!
    return unless current_user&.profile_incomplete?

    redirect_to onboarding_profile_path,
                alert: "Complete seu nome e apelido para continuar."
  end
end
