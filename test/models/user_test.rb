require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "requires a username for new users" do
    user = User.new(email: "user@example.com", password: "password123")

    assert_not user.valid?
    assert_includes user.errors[:username], "não pode ficar em branco"
  end

  test "accepts usernames with letters numbers underscores and dots" do
    user = User.new(
      username: "player_01.test",
      email: "user@example.com",
      password: "password123"
    )

    assert user.valid?
  end

  test "rejects usernames with unsupported characters" do
    user = User.new(
      username: "player-name",
      email: "user@example.com",
      password: "password123"
    )

    assert_not user.valid?
    assert user.errors[:username].any?
  end

  test "does not allow duplicate usernames" do
    User.create!(
      username: "player.one",
      email: "first@example.com",
      password: "password123"
    )
    duplicate = User.new(
      username: "player.one",
      email: "second@example.com",
      password: "password123"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:username], "já está em uso"
  end

  test "allows usernames that differ by case" do
    User.create!(
      username: "Player.One",
      email: "first@example.com",
      password: "password123"
    )
    user = User.new(
      username: "player.one",
      email: "second@example.com",
      password: "password123"
    )

    assert user.valid?
  end

  test "allows existing users without a username to be updated" do
    user = User.create!(
      username: "legacy.user",
      email: "legacy@example.com",
      password: "password123"
    )
    user.update_column(:username, nil)

    assert user.update(name: "Legacy User")
  end

  test "accepts a valid CPF for payment identification" do
    user = User.new(
      username: "pix.player",
      email: "pix-player@example.com",
      password: "password123",
      cpf: "52998224725"
    )

    assert user.valid?
  end

  test "rejects an invalid CPF" do
    user = User.new(
      username: "invalid.cpf",
      email: "invalid-cpf@example.com",
      password: "password123",
      cpf: "12345678900"
    )

    assert_not user.valid?
    assert user.errors[:cpf].any?
  end

end
