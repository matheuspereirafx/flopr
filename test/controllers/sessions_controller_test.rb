require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "login page submits Google authentication outside Turbo" do
    get new_user_session_path

    assert_select "form[data-turbo='false'][action='/users/auth/google_oauth2'][method='post']"
  end

  test "player profile redirects to player tournaments after login" do
    user = User.create!(
      email: "player-login@example.com",
      password: "password123",
      username: "player_login"
    )

    post user_session_path,
         params: {
           role: "player",
           user: { email: user.email, password: "password123" }
         }

    assert_redirected_to player_tournaments_path
  end

  test "organizer profile redirects to clubs after login" do
    user = User.create!(
      email: "organizer-login@example.com",
      password: "password123",
      username: "organizer_login"
    )

    post user_session_path,
         params: {
           role: "organizer",
           user: { email: user.email, password: "password123" }
         }

    assert_redirected_to clubs_path
  end
end
