require "test_helper"

class UserTest < ActiveSupport::TestCase
  # ====================
  # Factory Tests
  # ====================
  test "valid user factory should be valid" do
    user = build(:user)
    assert user.valid?, "User factory should create valid user"
  end

  test "admin user factory should be valid" do
    admin = build(:user, :admin)
    assert admin.valid?, "Admin user factory should create valid user"
    assert admin.admin?, "Admin factory should create admin user"
  end

  # ====================
  # Email Validations
  # ====================
  test "should require email" do
    user = build(:user, email: nil)
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "should require valid email format" do
    invalid_emails = %w[user.com @example.com user@]

    invalid_emails.each do |invalid_email|
      user = build(:user, email: invalid_email)
      assert_not user.valid?, "#{invalid_email} should be invalid"
    end
  end

  test "should accept valid email formats" do
    valid_emails = %w[user@example.com USER@example.COM user+tag@example.cl test.user@example.com]

    valid_emails.each do |valid_email|
      user = build(:user, email: valid_email)
      assert user.valid?, "#{valid_email} should be valid"
    end
  end

  test "should enforce unique email" do
    user1 = create(:user, email: "duplicate@roraima.cl")
    user2 = build(:user, email: "duplicate@roraima.cl")

    assert_not user2.valid?
    assert_includes user2.errors[:email], "has already been taken"
  end

  test "should enforce unique email case insensitively" do
    user1 = create(:user, email: "test@roraima.cl")
    user2 = build(:user, email: "TEST@roraima.cl")

    assert_not user2.valid?, "Email uniqueness should be case-insensitive"
    assert_includes user2.errors[:email], "has already been taken"
  end

  # ====================
  # Password Validations (Devise)
  # ====================
  test "should require password on creation" do
    user = build(:user, password: nil, password_confirmation: nil)
    assert_not user.valid?
    assert_includes user.errors[:password], "can't be blank"
  end

  test "should require password confirmation to match" do
    user = build(:user, password: "password123", password_confirmation: "different")
    assert_not user.valid?
    assert_includes user.errors[:password_confirmation], "doesn't match Password"
  end

  test "should enforce minimum password length" do
    user = build(:user, password: "short", password_confirmation: "short")
    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 6 characters)"
  end

  test "should accept valid password" do
    user = build(:user, password: "validpassword", password_confirmation: "validpassword")
    assert user.valid?
  end

  # ====================
  # Admin Role
  # ====================
  test "admin? should return true for admin users" do
    admin = create(:user, :admin)
    assert admin.admin?, "admin? should return true for admin user"
  end

  test "admin? should return false for regular users" do
    user = create(:user)
    assert_not user.admin?, "admin? should return false for regular user"
  end

  test "should default admin to false" do
    user = create(:user)
    assert_equal false, user.admin
  end

  # ====================
  # Associations
  # ====================
  test "should have many packages" do
    user = create(:user)
    assert_respond_to user, :packages
  end

  test "should destroy associated packages when user is destroyed" do
    user = create(:user)
    package1 = create(:package, user: user)
    package2 = create(:package, user: user)

    assert_difference "Package.count", -2 do
      user.destroy
    end
  end

  test "should have zero packages for new user" do
    user = create(:user)
    assert_equal 0, user.packages.count
  end

  test "should correctly count associated packages" do
    user = create(:user)
    create_list(:package, 3, user: user)

    assert_equal 3, user.packages.count
  end

  # ====================
  # Edge Cases
  # ====================
  test "should handle email with special characters" do
    user = create(:user, email: "user+tag123@example.com")
    assert user.valid?
    assert_equal "user+tag123@example.com", user.email
  end

  test "should not allow duplicate email with different case" do
    create(:user, email: "CaseSensitive@Example.COM")
    duplicate = build(:user, email: "casesensitive@example.com")

    assert_not duplicate.valid?
  end

  # ====================
  # Factory Traits
  # ====================
  test "with_packages trait should create user with packages" do
    user = create(:user, :with_packages)
    assert_equal 3, user.packages.count
  end
end
