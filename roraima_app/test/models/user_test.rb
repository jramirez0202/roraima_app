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
    user = create(:user, :customer)
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

  # ====================
  # DRIVER Validations
  # ====================
  test "driver should require email" do
    driver = build(:user, role: :driver, email: nil)
    assert_not driver.valid?
    assert_includes driver.errors[:email], "can't be blank"
  end

  test "driver should require password" do
    driver = build(:user, role: :driver, password: nil, password_confirmation: nil)
    assert_not driver.valid?
    assert_includes driver.errors[:password], "can't be blank"
  end

  test "driver should require rut" do
    driver = build(:user, role: :driver, rut: nil)
    assert_not driver.valid?
    assert_includes driver.errors[:rut], "no puede estar vacío"
  end

  test "driver should require phone" do
    driver = build(:user, role: :driver, phone: nil)
    assert_not driver.valid?
    assert_includes driver.errors[:phone], "no puede estar vacío"
  end

  test "driver should validate rut format" do
    driver = build(:user, role: :driver, rut: "invalid-rut")
    assert_not driver.valid?
    assert_includes driver.errors[:rut], "debe tener formato válido (ej: 12.345.678-9)"
  end

  test "driver should validate phone format" do
    driver = build(:user, role: :driver, phone: "123456789")
    assert_not driver.valid?
    assert_includes driver.errors[:phone], "debe tener formato +569XXXXXXXX (12 caracteres)"
  end

  test "driver should require unique rut" do
    create(:user, role: :driver, rut: "12.345.678-9", phone: "+56987654321")
    duplicate = build(:user, role: :driver, rut: "12.345.678-9", phone: "+56987654322")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:rut], "has already been taken"
  end

  test "driver should be valid with all required fields" do
    driver = build(:user,
      role: :driver,
      email: "driver@example.com",
      password: "password123",
      password_confirmation: "password123",
      rut: "11.111.111-1",
      phone: "+56987654321"
    )
    assert driver.valid?, "Driver should be valid with all required fields: #{driver.errors.full_messages}"
  end

  # ====================
  # CUSTOMER Validations
  # ====================
  test "customer should require email" do
    customer = build(:user, role: :customer, email: nil)
    assert_not customer.valid?
    assert_includes customer.errors[:email], "can't be blank"
  end

  test "customer should require password" do
    customer = build(:user, role: :customer, password: nil, password_confirmation: nil)
    assert_not customer.valid?
    assert_includes customer.errors[:password], "can't be blank"
  end

  test "customer should require rut" do
    customer = build(:user, role: :customer, rut: nil)
    assert_not customer.valid?
    assert_includes customer.errors[:rut], "no puede estar vacío"
  end

  test "customer should require phone" do
    customer = build(:user, role: :customer, phone: nil)
    assert_not customer.valid?
    assert_includes customer.errors[:phone], "no puede estar vacío"
  end

  test "customer should require company" do
    customer = build(:user, role: :customer, company: nil)
    assert_not customer.valid?
    assert_includes customer.errors[:company], "no puede estar vacío"
  end

  test "customer should require delivery_charge" do
    customer = build(:user, role: :customer, delivery_charge: nil)
    assert_not customer.valid?
    assert_includes customer.errors[:delivery_charge], "no puede estar vacío"
  end

  test "customer should validate rut format" do
    customer = build(:user, role: :customer, rut: "invalid-rut")
    assert_not customer.valid?
    assert_includes customer.errors[:rut], "debe tener formato válido (ej: 12.345.678-9)"
  end

  test "customer should validate phone format" do
    customer = build(:user, role: :customer, phone: "123456789")
    assert_not customer.valid?
    assert_includes customer.errors[:phone], "debe tener formato +569XXXXXXXX (12 caracteres)"
  end

  test "customer should validate delivery_charge is non-negative" do
    customer = build(:user, role: :customer, delivery_charge: -100)
    assert_not customer.valid?
    assert_includes customer.errors[:delivery_charge], "must be greater than or equal to 0"
  end

  test "customer should require unique rut" do
    create(:user, role: :customer, rut: "22.222.222-2", phone: "+56987654321", company: "Company A", delivery_charge: 1000)
    duplicate = build(:user, role: :customer, rut: "22.222.222-2", phone: "+56987654322", company: "Company B", delivery_charge: 2000)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:rut], "has already been taken"
  end

  test "customer should be valid with all required fields" do
    customer = build(:user,
      role: :customer,
      email: "customer@example.com",
      password: "password123",
      password_confirmation: "password123",
      rut: "33.333.333-3",
      phone: "+56987654321",
      company: "Test Company",
      delivery_charge: 5000
    )
    assert customer.valid?, "Customer should be valid with all required fields: #{customer.errors.full_messages}"
  end

  test "customer should allow zero delivery_charge" do
    customer = build(:user,
      role: :customer,
      email: "customer@example.com",
      password: "password123",
      password_confirmation: "password123",
      rut: "44.444.444-4",
      phone: "+56987654321",
      company: "Test Company",
      delivery_charge: 0
    )
    assert customer.valid?, "Customer should allow 0 delivery_charge: #{customer.errors.full_messages}"
  end

  # ====================
  # ADMIN Validations (no extra fields required)
  # ====================
  test "admin should only require email and password" do
    admin = build(:user,
      role: :admin,
      email: "admin@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    assert admin.valid?, "Admin should be valid with only email and password: #{admin.errors.full_messages}"
  end

  test "admin should not require rut" do
    admin = build(:user, role: :admin, rut: nil)
    assert admin.valid?, "Admin should not require rut"
  end

  test "admin should not require phone" do
    admin = build(:user, role: :admin, phone: nil)
    assert admin.valid?, "Admin should not require phone"
  end

  test "admin should not require company" do
    admin = build(:user, role: :admin, company: nil)
    assert admin.valid?, "Admin should not require company"
  end
end
