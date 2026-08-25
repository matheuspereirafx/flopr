require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "renders the sign up form" do
    get new_user_registration_path

    assert_response :success
  end

  test "creates a user when terms are accepted" do
    email = "new-user@example.com"
    username = "new.user"

    assert_difference -> { User.count }, 1 do
      post user_registration_path, params: {
        user: {
          username: username,
          email: email,
          password: "password123",
          password_confirmation: "password123",
          terms: "1"
        }
      }
    end

    assert_equal email, User.find_by!(email: email).email
    assert_equal username, User.find_by!(email: email).username
  end

  test "does not create a user without a username" do
    assert_no_difference -> { User.count } do
      post user_registration_path, params: {
        user: {
          email: "missing-username@example.com",
          password: "password123",
          password_confirmation: "password123",
          terms: "1"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "does not create a user with an invalid username" do
    assert_no_difference -> { User.count } do
      post user_registration_path, params: {
        user: {
          username: "invalid username",
          email: "invalid-username@example.com",
          password: "password123",
          password_confirmation: "password123",
          terms: "1"
        }
      }
    end

    assert_response :unprocessable_entity
  end
end
