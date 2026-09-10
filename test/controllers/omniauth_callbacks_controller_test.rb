require "test_helper"

class OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @request_validation_phase = OmniAuth.config.request_validation_phase
    OmniAuth.config.test_mode = true
    OmniAuth.config.request_validation_phase = nil
  end

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.request_validation_phase = @request_validation_phase
    OmniAuth.config.mock_auth.delete(:google_oauth2)
  end

  test "creates a Google user and redirects to profile completion" do
    OmniAuth.config.mock_auth[:google_oauth2] = google_auth

    assert_difference -> { User.count }, 1 do
      get user_google_oauth2_omniauth_callback_path
    end

    assert_redirected_to onboarding_profile_path
    assert_equal "callback-google@example.com", User.last.email
  end

  test "redirects to login when Google does not provide a verified email" do
    OmniAuth.config.mock_auth[:google_oauth2] = google_auth(email_verified: false)

    get user_google_oauth2_omniauth_callback_path

    assert_redirected_to new_user_session_path
    assert_equal "Não foi possível entrar com Google: O e-mail do Google precisa ser verificado.", flash[:alert]
  end

  private

  def google_auth(email_verified: true)
    OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "callback-google-user-123",
      info: { email: "callback-google@example.com" },
      extra: { raw_info: { email_verified: email_verified } }
    )
  end
end
