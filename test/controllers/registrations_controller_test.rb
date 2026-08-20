require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "renders the sign up form" do
    get new_user_registration_path

    assert_response :success
  end

  test "creates a user when terms are accepted" do
    email = "new-user@example.com"

    assert_difference -> { User.count }, 1 do
      post user_registration_path, params: {
        user: {
          email: email,
          password: "password123",
          password_confirmation: "password123",
          terms: "1"
        }
      }
    end

    assert_equal email, User.find_by!(email: email).email
  end
end
