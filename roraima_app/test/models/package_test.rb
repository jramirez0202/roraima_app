require "test_helper"

class PackageTest < ActiveSupport::TestCase
  # ====================
  # Factory Tests
  # ====================
  test "valid package factory should be valid" do
    package = build(:package)
    assert package.valid?, "Package factory should create valid package"
  end

  test "complete package factory should be valid" do
    package = build(:package, :complete)
    assert package.valid?, "Complete package factory should create valid package"
  end

  test "minimal package factory should be valid" do
    package = build(:package, :minimal)
    assert package.valid?, "Minimal package factory should create valid package with required fields only"
  end

  # ====================
  # Phone Presence Validation
  # ====================
  test "should require phone" do
    package = build(:package, phone: nil)
    assert_not package.valid?
    assert_includes package.errors[:phone], "es obligatorio"
  end

  test "should not allow empty phone" do
    package = build(:package, phone: "")
    assert_not package.valid?
    assert_includes package.errors[:phone], "es obligatorio"
  end

  test "should not allow blank phone" do
    package = build(:package, phone: "   ")
    assert_not package.valid?
    assert_includes package.errors[:phone], "debe tener formato +569XXXXXXXX (12 caracteres)"
  end

  # ====================
  # Phone Format Validation - Valid Cases
  # ====================
  test "should accept valid phone format +569XXXXXXXX" do
    valid_phones = [
      "+56912345678",
      "+56987654321",
      "+56900000000",
      "+56999999999"
    ]

    valid_phones.each do |valid_phone|
      package = build(:package, phone: valid_phone)
      assert package.valid?, "#{valid_phone} should be valid"
    end
  end

  test "should accept phone starting with +569" do
    package = build(:package, phone: "+56911111111")
    assert package.valid?
  end

  test "should accept exactly 12 characters" do
    package = build(:package, phone: "+56912345678")
    assert package.valid?
    assert_equal 12, package.phone.length
  end

  # ====================
  # Phone Format Validation - Invalid Cases
  # ====================
  test "should reject phone with spaces" do
    invalid_phones = [
      "+56 9 1234 5678",
      "+569 1234 5678",
      "+56 912345678",
      " +56912345678",
      "+56912345678 "
    ]

    invalid_phones.each do |invalid_phone|
      package = build(:package, phone: invalid_phone)
      assert_not package.valid?, "#{invalid_phone} should be invalid"
      assert_includes package.errors[:phone], "debe tener formato +569XXXXXXXX (12 caracteres)"
    end
  end

  test "should reject phone with wrong prefix" do
    invalid_phones = [
      "+56812345678",  # +568 instead of +569
      "+56712345678",  # +567 instead of +569
      "+56012345678",  # +560 instead of +569
      "56912345678",   # Missing +
      "912345678"      # Missing +56
    ]

    invalid_phones.each do |invalid_phone|
      package = build(:package, phone: invalid_phone)
      assert_not package.valid?, "#{invalid_phone} should be invalid (wrong prefix)"
      assert_includes package.errors[:phone], "debe tener formato +569XXXXXXXX (12 caracteres)"
    end
  end

  test "should reject phone that is too short" do
    invalid_phones = [
      "+5691234567",   # 11 chars (missing 1 digit)
      "+569123456",    # 10 chars (missing 2 digits)
      "+56912345",     # 9 chars
      "+569"           # Only prefix
    ]

    invalid_phones.each do |invalid_phone|
      package = build(:package, phone: invalid_phone)
      assert_not package.valid?, "#{invalid_phone} should be invalid (too short)"
      assert_includes package.errors[:phone], "debe tener formato +569XXXXXXXX (12 caracteres)"
    end
  end

  test "should reject phone that is too long" do
    invalid_phones = [
      "+569123456789",  # 13 chars (1 extra digit)
      "+5691234567890", # 14 chars (2 extra digits)
      "+56912345678901" # 15 chars
    ]

    invalid_phones.each do |invalid_phone|
      package = build(:package, phone: invalid_phone)
      assert_not package.valid?, "#{invalid_phone} should be invalid (too long)"
      assert_includes package.errors[:phone], "debe tener formato +569XXXXXXXX (12 caracteres)"
    end
  end

  test "should reject phone with letters" do
    invalid_phones = [
      "+569abcdefgh",
      "+56912345abc",
      "+569XXXXXXXX",
      "phone"
    ]

    invalid_phones.each do |invalid_phone|
      package = build(:package, phone: invalid_phone)
      assert_not package.valid?, "#{invalid_phone} should be invalid (contains letters)"
      assert_includes package.errors[:phone], "debe tener formato +569XXXXXXXX (12 caracteres)"
    end
  end

  test "should reject phone with special characters" do
    invalid_phones = [
      "+569-1234-5678",
      "+569(12)345678",
      "+569.1234.5678",
      "+569/12345678"
    ]

    invalid_phones.each do |invalid_phone|
      package = build(:package, phone: invalid_phone)
      assert_not package.valid?, "#{invalid_phone} should be invalid (contains special chars)"
      assert_includes package.errors[:phone], "debe tener formato +569XXXXXXXX (12 caracteres)"
    end
  end

  test "should reject international formats" do
    invalid_phones = [
      "+1234567890",     # US format
      "+441234567890",   # UK format
      "+34123456789",    # Spain format
      "+5511234567890"   # Brazil format
    ]

    invalid_phones.each do |invalid_phone|
      package = build(:package, phone: invalid_phone)
      assert_not package.valid?, "#{invalid_phone} should be invalid (wrong country)"
      assert_includes package.errors[:phone], "debe tener formato +569XXXXXXXX (12 caracteres)"
    end
  end

  # ====================
  # Other Required Field Validations
  # ====================
  test "should require region" do
    package = build(:package, region: nil)
    assert_not package.valid?
    assert_includes package.errors[:region], "can't be blank"
  end

  test "should require commune" do
    package = build(:package, commune: nil)
    assert_not package.valid?
    assert_includes package.errors[:commune], "can't be blank"
  end

  test "should require loading_date" do
    package = build(:package, loading_date: nil)
    assert_not package.valid?
    assert_includes package.errors[:loading_date], "can't be blank"
  end

  # ====================
  # Loading Date Validation
  # ====================
  test "should not allow past loading_date" do
    package = build(:package, :past_date)
    assert_not package.valid?
    assert_includes package.errors[:loading_date], "debe ser hoy o posterior"
  end

  test "should allow today as loading_date" do
    package = build(:package, loading_date: Date.today)
    assert package.valid?
  end

  test "should allow future loading_date" do
    package = build(:package, loading_date: Date.tomorrow)
    assert package.valid?
  end

  # ====================
  # Address and Description Length Validation
  # ====================
  test "should allow address up to 100 characters" do
    package = build(:package, address: "A" * 100)
    assert package.valid?
  end

  test "should reject address over 100 characters" do
    package = build(:package, address: "A" * 101)
    assert_not package.valid?
    assert_includes package.errors[:address], "no puede tener más de 100 caracteres"
  end

  test "should allow description up to 100 characters" do
    package = build(:package, description: "D" * 100)
    assert package.valid?
  end

  test "should reject description over 100 characters" do
    package = build(:package, description: "D" * 101)
    assert_not package.valid?
    assert_includes package.errors[:description], "no puede tener más de 100 caracteres"
  end

  # ====================
  # Amount Validation
  # ====================
  test "should allow amount of zero" do
    package = build(:package, amount: 0)
    assert package.valid?
  end

  test "should allow positive amount" do
    package = build(:package, amount: 1000)
    assert package.valid?
  end

  test "should not allow negative amount" do
    package = build(:package, amount: -100)
    assert_not package.valid?
    assert_includes package.errors[:amount], "must be greater than or equal to 0"
  end

  # ====================
  # Tracking Code Validation
  # ====================
  test "should generate tracking_code on create" do
    package = create(:package)
    assert_not_nil package.tracking_code
    assert package.tracking_code.starts_with?("PKG-")
  end

  test "should have unique tracking_code" do
    package1 = create(:package)
    package2 = create(:package)

    assert_not_equal package1.tracking_code, package2.tracking_code
  end

  test "tracking_code should have correct format" do
    package = create(:package)
    # PKG- + 14 digits
    assert_match /\APKG-\d{14}\z/, package.tracking_code
  end

  # ====================
  # Status Enum
  # ====================
  test "should default to active status" do
    package = create(:package)
    assert package.active?
    assert_not package.cancelado?
  end

  test "should allow cancelling package" do
    package = create(:package)
    user = create(:user)
    package.cancel!(user: user)

    assert package.cancelado?
    assert_not package.active?
    assert_not_nil package.cancelled_at
  end

  # ====================
  # ready_for_label? Method
  # ====================
  test "ready_for_label? should return true when all label fields present" do
    package = build(:package,
      tracking_code: "PKG-12345678901234",
      customer_name: "Test Customer",
      address: "Test Address",
      phone: "+56912345678",
      loading_date: Date.tomorrow
    )

    assert package.ready_for_label?, "Package should be ready for label with all required fields"
  end

  test "ready_for_label? should return false when phone is missing" do
    package = build(:package,
      tracking_code: "PKG-12345678901234",
      customer_name: "Test Customer",
      address: "Test Address",
      phone: nil,
      loading_date: Date.tomorrow
    )

    assert_not package.ready_for_label?, "Package should not be ready without phone"
  end

  test "ready_for_label? should return false when customer_name is missing" do
    package = build(:package,
      tracking_code: "PKG-12345678901234",
      customer_name: nil,
      address: "Test Address",
      phone: "+56912345678",
      loading_date: Date.tomorrow
    )

    assert_not package.ready_for_label?, "Package should not be ready without customer_name"
  end

  test "ready_for_label? should return false when address is missing" do
    package = build(:package,
      tracking_code: "PKG-12345678901234",
      customer_name: "Test Customer",
      address: nil,
      phone: "+56912345678",
      loading_date: Date.tomorrow
    )

    assert_not package.ready_for_label?, "Package should not be ready without address"
  end

  test "ready_for_label? should return false when loading_date is missing" do
    package = build(:package,
      tracking_code: "PKG-12345678901234",
      customer_name: "Test Customer",
      address: "Test Address",
      phone: "+56912345678",
      loading_date: nil
    )

    assert_not package.ready_for_label?, "Package should not be ready without loading_date"
  end

  # ====================
  # formatted_amount Method
  # ====================
  test "formatted_amount should format Chilean peso correctly" do
    package = build(:package, amount: 1000)
    assert_equal "$1.000 CLP", package.formatted_amount
  end

  test "formatted_amount should handle zero" do
    package = build(:package, amount: 0)
    assert_equal "$0 CLP", package.formatted_amount
  end

  test "formatted_amount should handle large amounts" do
    package = build(:package, amount: 1000000)
    assert_equal "$1.000.000 CLP", package.formatted_amount
  end

  # ====================
  # Associations
  # ====================
  test "should belong to region" do
    package = create(:package)
    assert_respond_to package, :region
    assert_instance_of Region, package.region
  end

  test "should belong to commune" do
    package = create(:package)
    assert_respond_to package, :commune
    assert_instance_of Commune, package.commune
  end

  test "should belong to user" do
    package = create(:package)
    assert_respond_to package, :user
    assert_instance_of User, package.user
  end

  test "user should be optional" do
    package = build(:package, user: nil)
    assert package.valid?, "Package should be valid without user"
  end

  # ====================
  # Edge Cases
  # ====================
  test "should handle package with all optional fields empty" do
    package = build(:package, :minimal)
    assert package.valid?, "Package should be valid with only required fields"
  end

  test "should handle exchange flag" do
    package = build(:package, exchange: true)
    assert package.valid?
    assert package.exchange
  end

  test "should validate phone format even for old records on update" do
    # Simular un registro viejo con formato antiguo
    # (en realidad esto fallaría porque tenemos validación en create también)
    package = create(:package, phone: "+56912345678")

    # Al actualizar, debe seguir siendo válido si no cambia el phone
    package.customer_name = "New Name"
    assert package.valid?, "Updating other fields should work"

    # Pero si intenta cambiar a formato inválido, debe fallar
    package.phone = "+56 9 1234 5678"
    assert_not package.valid?, "Updating to invalid phone format should fail"
  end
end
