module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def google_oauth2
      user = User.from_google_oauth!(request.env.fetch("omniauth.auth"))

      sign_in_and_redirect user, event: :authentication
    rescue ArgumentError, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
      redirect_to new_user_session_path,
                  alert: "Não foi possível entrar com Google: #{e.message}"
    end

    def failure
      redirect_to new_user_session_path,
                  alert: "Não foi possível entrar com Google. Tente novamente."
    end

    protected

    def after_sign_in_path_for(resource)
      return onboarding_profile_path if resource.profile_incomplete?

      case request.env.dig("omniauth.params", "role")
      when "player"
        player_tournaments_path
      when "organizer"
        clubs_path
      else
        super
      end
    end
  end
end
