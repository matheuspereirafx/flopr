require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.from_google_oauth!(google_auth)
    sign_in @user
  end

  test "shows the profile completion form for a Google user" do
    get onboarding_profile_path

    assert_response :success
    assert_select "input[name='user[name]'][required]"
    assert_select "input[name='user[username]'][required]"
  end

  test "completes the profile with a name and username" do
    patch onboarding_profile_path,
          params: { user: { name: "Google User", username: "google.user" } }

    assert_redirected_to root_path
    assert_equal "Google User", @user.reload.name
    assert_equal "google.user", @user.username
    assert_not @user.profile_incomplete?
  end

  test "does not complete the profile without a username" do
    patch onboarding_profile_path, params: { user: { name: "Google User", username: "" } }

    assert_response :unprocessable_entity
    assert @user.reload.profile_incomplete?
  end

  test "redirects an incomplete Google profile away from private pages" do
    get clubs_path

    assert_redirected_to onboarding_profile_path
  end

  private

  def google_auth
    OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "profiles-google-user-123",
      info: { email: "profiles-google@example.com" },
      extra: { raw_info: { email_verified: true } }
    )
  end
end
