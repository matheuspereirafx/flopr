require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "is valid when terms are accepted" do
    user = User.new(
      email: "player@example.com",
      password: "password",
      terms: "1"
    )

    assert user.valid?
  end

  test "requires acceptance of terms" do
    user = User.new(
      email: "player@example.com",
      password: "password",
      terms: "0"
    )

    assert_not user.valid?
    assert_includes user.errors.details[:terms], { error: :accepted }
  end

  test "does not require terms when updating an existing user" do
    user = User.create!(
      email: "player@example.com",
      password: "password",
      terms: "1"
    )

    assert user.update(name: "Player One")
  end
end
