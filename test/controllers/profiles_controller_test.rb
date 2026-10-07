require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.from_google_oauth!(google_auth)
    @user.update!(password: "password123")
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

  test "shows the authenticated user's profile settings" do
    @user.update!(name: "Google User", username: "google.user")

    get profile_path

    assert_response :success
    assert_select "input[name='user[email]'][disabled]", value: @user.email
    assert_select "input[name='user[name]']", value: "Google User"
    assert_select "input[name='user[username]']", value: "google.user"
    assert_select "input[name='user[cpf]']"
    assert_select "input[name='user[current_password]']"
    assert_select "input[name='user[password]']"
    assert_select "input[name='user[password_confirmation]']"
  end

  test "updates the profile data without allowing the email to be changed" do
    patch profile_path,
          params: {
            user: {
              name: "Updated Name",
              username: "updated.user",
              cpf: "529.982.247-25",
              email: "changed@example.com"
            }
          }

    assert_redirected_to profile_path
    assert_equal "Updated Name", @user.reload.name
    assert_equal "updated.user", @user.username
    assert_equal "52998224725", @user.cpf
    assert_equal "profiles-google@example.com", @user.email
  end

  test "changes the password with the current password" do
    patch profile_path,
          params: {
            user: {
              current_password: "password123",
              password: "new-password123",
              password_confirmation: "new-password123"
            }
          }

    assert_redirected_to profile_path
    assert @user.reload.valid_password?("new-password123")
  end

  test "does not change the password with an invalid current password" do
    patch profile_path,
          params: {
            user: {
              current_password: "wrong-password",
              password: "new-password123",
              password_confirmation: "new-password123"
            }
          }

    assert_response :unprocessable_entity
    assert @user.reload.valid_password?("password123")
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
