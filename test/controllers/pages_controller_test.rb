require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "navbar-user@example.com",
      password: "password123",
      name: "Navbar User",
      username: "navbar_user"
    )
  end

  test "visitor sees authentication calls to action on the home page" do
    get root_path

    assert_response :success
    assert_select ".app-navbar", count: 0
    assert_select "a[href='#{access_path}']", text: "Entrar", count: 1
    assert_select "a[href='#{new_user_registration_path}']", text: "Criar conta", count: 2
    assert_select "a[href='#{new_user_registration_path}']", text: "Criar meu torneio agora", count: 1
  end

  test "authenticated user sees the profile navigation and no authentication calls to action" do
    sign_in @user
    get root_path

    assert_response :success
    assert_select ".app-navbar", count: 0
    assert_select ".landing-nav .app-navbar__profile-menu", count: 1
    assert_select ".landing-nav .app-navbar__profile-link[href='#{access_path}']", text: "Escolha sua navegação", count: 1
    assert_select ".landing-nav .app-navbar__profile-link[href='#{onboarding_profile_path}']", text: "Meu perfil", count: 1
    assert_select ".landing-nav__actions > a", count: 0
    assert_select ".landing-hero__actions a[href='#{new_user_registration_path}']", count: 0
    assert_select ".landing-cta a[href='#{new_user_registration_path}']", count: 0
  end

  test "private club and player areas use the profile navigation without section links" do
    sign_in @user

    [clubs_path, player_tournaments_path].each do |path|
      get path

      assert_response :success
      assert_select ".app-navbar", count: 1
      assert_select ".app-navbar__links", count: 0
      assert_select ".app-navbar__profile-link[href='#{access_path}']", text: "Escolha sua navegação", count: 1
    end
  end
end
