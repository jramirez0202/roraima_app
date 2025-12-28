ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    # fixtures :all  # Disabled - using FactoryBot instead

    # Include FactoryBot methods
    include FactoryBot::Syntax::Methods

    # Add more helper methods to be used by all tests here...
  end
end

# Configuration for controller and integration tests
class ActionDispatch::IntegrationTest
  # Include Devise test helpers for authentication
  include Devise::Test::IntegrationHelpers

  # Helper method to sign in as admin
  def sign_in_as_admin
    @admin_user ||= create(:user, :admin)
    sign_in @admin_user
    @admin_user
  end

  # Helper method to sign in as regular user
  def sign_in_as_user
    @regular_user ||= create(:user)
    sign_in @regular_user
    @regular_user
  end
end
