require "test_helper"

class Admin::BaseControllerTest < ActionDispatch::IntegrationTest
  # Test admin authorization using PackagesController as a concrete implementation
  # since BaseController is abstract

  # ====================
  # Authorization Tests
  # ====================
  test "should redirect non-admin users to root path" do
    user = sign_in_as_user

    get admin_packages_url

    assert_redirected_to customers_dashboard_path
    assert_equal "No tienes permiso para acceder a esta sección.", flash[:alert]
  end

  test "should allow admin users to access admin area" do
    admin = sign_in_as_admin

    get admin_packages_url

    assert_response :success
    assert_nil flash[:alert]
  end

  test "should redirect when current_user is nil (not signed in)" do
    # Don't sign in - test unauthenticated access
    get admin_packages_url

    # ApplicationController requires authentication, so this will redirect to sign in
    # But if somehow they bypass that, BaseController should also block them
    assert_redirected_to new_user_session_path
  end

  test "should check admin status using admin? method" do
    regular_user = create(:user, :customer)  # Usar trait en lugar de admin: false
    sign_in regular_user

    get admin_packages_url

    assert_redirected_to customers_dashboard_path
    assert_equal "No tienes permiso para acceder a esta sección.", flash[:alert]
  end

  test "should allow access when admin flag is true" do
    admin_user = create(:user, :admin)  # Usar trait en lugar de admin: true
    sign_in admin_user

    get admin_packages_url

    assert_response :success
  end

  # ====================
  # Edge Cases
  # ====================
  test "should handle user with admin flag set to true explicitly" do
    user = create(:user)
    user.update(role: :admin)  # Usar role enum en lugar de admin boolean
    sign_in user

    get admin_packages_url

    assert_response :success
  end

  test "should handle user with admin flag set to false explicitly" do
    admin = create(:user, :admin)
    admin.update(role: :customer)  # Usar role enum en lugar de admin boolean
    sign_in admin

    get admin_packages_url

    assert_redirected_to customers_dashboard_path
  end

  # ====================
  # Multiple Controllers Test
  # ====================
  test "should protect users controller with same authorization" do
    user = sign_in_as_user

    get admin_users_url

    assert_redirected_to customers_dashboard_path
    assert_equal "No tienes permiso para acceder a esta sección.", flash[:alert]
  end

  test "should allow admin to access users controller" do
    admin = sign_in_as_admin

    get admin_users_url

    assert_response :success
  end

  # ====================
  # Before Action Test
  # ====================
  test "check_admin should be called before any action" do
    # This tests that the before_action :check_admin is properly set up
    regular_user = create(:user, :customer)  # Usar trait en lugar de admin: false
    sign_in regular_user

    # Try different actions on admin controllers
    get admin_packages_url  # index
    assert_redirected_to customers_dashboard_path

    get new_admin_package_url  # new
    assert_redirected_to customers_dashboard_path
  end
end
