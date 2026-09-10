require "test_helper"

class UserGoogleOauthTest < ActiveSupport::TestCase
  test "creates an incomplete account from a verified Google identity" do
    user = User.from_google_oauth!(google_auth(email: "google-user@example.com"))

    assert_equal "google_oauth2", user.provider
    assert_equal "google-user-123", user.uid
    assert user.profile_incomplete?
    assert_nil user.username
  end

  test "links a verified Google identity to an existing account with the same email" do
    user = User.create!(
      username: "existing.user",
      email: "existing@example.com",
      password: "password123"
    )

    assert_no_difference -> { User.count } do
      linked_user = User.from_google_oauth!(google_auth(email: user.email))

      assert_equal user, linked_user
    end

    assert_equal "google_oauth2", user.reload.provider
    assert_equal "google-user-123", user.uid
  end

  test "rejects a Google identity with an unverified email" do
    auth = google_auth(email_verified: false)

    error = assert_raises(ArgumentError) { User.from_google_oauth!(auth) }

    assert_equal "O e-mail do Google precisa ser verificado.", error.message
  end

  private

  def google_auth(email: "google@example.com", email_verified: true)
    OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "google-user-123",
      info: { email: email },
      extra: { raw_info: { email_verified: email_verified } }
    )
  end
end
