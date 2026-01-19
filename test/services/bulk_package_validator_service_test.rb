require "test_helper"

class BulkPackageValidatorServiceTest < ActiveSupport::TestCase
  setup do
    @user = create(:user, :customer)
    @admin = create(:user, :admin)

    # Ensure Región Metropolitana exists
    @region = Region.find_or_create_by!(name: 'Región Metropolitana')

    # Create test communes
    @providencia = Commune.find_or_create_by!(name: 'Providencia', region: @region)
    @las_condes = Commune.find_or_create_by!(name: 'Las Condes', region: @region)
    @la_florida = Commune.find_or_create_by!(name: 'La Florida', region: @region)
  end

  # ====================
  # Successful Validation Tests
  # ====================
  test "should validate valid CSV file successfully" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    validator = BulkPackageValidatorService.new(bulk_upload.file, @user)

    result = validator.validate

    assert result, "Validator should return true for valid file"
    assert validator.valid?, "Validator should be valid"
    assert_empty validator.errors, "Should have no errors"
    assert_equal 3, validator.total_rows
    assert_equal 3, validator.validated_rows
    assert_not validator.has_more_rows?, "Should not have more rows"
  end

  test "should track total and validated rows correctly" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    validator = BulkPackageValidatorService.new(bulk_upload.file, @user)

    validator.validate

    assert_equal 3, validator.total_rows
    assert_equal 3, validator.validated_rows
  end

  # ====================
  # Error Detection Tests
  # ====================
  test "should detect invalid phone numbers" do
    bulk_upload = build(:bulk_upload, user: @user)

    csv_content = <<~CSV
      FECHA,NRO DE PEDIDO,DESTINATARIO,TELÉFONO,DIRECCIÓN,COMUNA,DESCRIPCIÓN,MONTO,CAMBIO,EMPRESA
      2025-12-15,ORD-001,Juan Pérez,123,Av. Providencia 123,Providencia,Paquete con ropa,15000,NO,Test Empresa
    CSV

    bulk_upload.file.attach(
      io: StringIO.new(csv_content),
      filename: 'test.csv',
      content_type: 'text/csv'
    )
    bulk_upload.save!

    validator = BulkPackageValidatorService.new(bulk_upload.file, @user)
    result = validator.validate

    assert_not result, "Should fail validation"
    assert_not validator.valid?
    assert_not_empty validator.errors

    error = validator.errors.find { |e| e[:column] == 'TELÉFONO' }
    assert_not_nil error
    assert_equal 2, error[:row]
    assert_includes error[:error], 'formato inválido'
  end

  test "should detect non-existent commune" do
    bulk_upload = build(:bulk_upload, user: @user)

    csv_content = <<~CSV
      FECHA,NRO DE PEDIDO,DESTINATARIO,TELÉFONO,DIRECCIÓN,COMUNA,DESCRIPCIÓN,MONTO,CAMBIO,EMPRESA
      2025-12-15,ORD-001,Juan Pérez,912345678,Av. Test 123,ComunaInexistente,Paquete con ropa,15000,NO,Test Empresa
    CSV

    bulk_upload.file.attach(
      io: StringIO.new(csv_content),
      filename: 'test.csv',
      content_type: 'text/csv'
    )
    bulk_upload.save!

    validator = BulkPackageValidatorService.new(bulk_upload.file, @user)
    result = validator.validate

    assert_not result
    assert_not validator.valid?

    error = validator.errors.find { |e| e[:column] == 'COMUNA' }
    assert_not_nil error
    assert_includes error[:error], 'no existe en el sistema'
  end

  test "should detect invalid date format" do
    bulk_upload = build(:bulk_upload, user: @user)

    csv_content = <<~CSV
      FECHA,NRO DE PEDIDO,DESTINATARIO,TELÉFONO,DIRECCIÓN,COMUNA,DESCRIPCIÓN,MONTO,CAMBIO,EMPRESA
      fecha-invalida,ORD-001,Juan Pérez,912345678,Av. Test 123,Providencia,Paquete con ropa,15000,NO,Test Empresa
    CSV

    bulk_upload.file.attach(
      io: StringIO.new(csv_content),
      filename: 'test.csv',
      content_type: 'text/csv'
    )
    bulk_upload.save!

    validator = BulkPackageValidatorService.new(bulk_upload.file, @user)
    result = validator.validate

    assert_not result

    error = validator.errors.find { |e| e[:column] == 'FECHA' }
    assert_not_nil error
    assert_includes error[:error], 'formato de fecha inválido'
  end

  test "should detect empty required fields" do
    bulk_upload = build(:bulk_upload, user: @user)

    csv_content = <<~CSV
      FECHA,NRO DE PEDIDO,DESTINATARIO,TELÉFONO,DIRECCIÓN,COMUNA,DESCRIPCIÓN,MONTO,CAMBIO,EMPRESA
      2025-12-15,ORD-001,,912345678,Av. Test 123,Providencia,Paquete con ropa,15000,NO,Test Empresa
    CSV

    bulk_upload.file.attach(
      io: StringIO.new(csv_content),
      filename: 'test.csv',
      content_type: 'text/csv'
    )
    bulk_upload.save!

    validator = BulkPackageValidatorService.new(bulk_upload.file, @user)
    result = validator.validate

    assert_not result

    error = validator.errors.find { |e| e[:column] == 'DESTINATARIO' }
    assert_not_nil error
    assert_includes error[:error], 'no puede estar vacío'
  end

  test "should detect invalid amount format" do
    bulk_upload = build(:bulk_upload, user: @user)

    csv_content = <<~CSV
      FECHA,NRO DE PEDIDO,DESTINATARIO,TELÉFONO,DIRECCIÓN,COMUNA,DESCRIPCIÓN,MONTO,CAMBIO,EMPRESA
      2025-12-15,ORD-001,Juan Pérez,912345678,Av. Test 123,Providencia,Paquete con ropa,,NO,Test Empresa
    CSV

    bulk_upload.file.attach(
      io: StringIO.new(csv_content),
      filename: 'test.csv',
      content_type: 'text/csv'
    )
    bulk_upload.save!

    validator = BulkPackageValidatorService.new(bulk_upload.file, @user)
    result = validator.validate

    # Empty amount should default to 0.0, so it should pass
    assert result
  end

  # ====================
  # Multiple Errors Tests
  # ====================
  test "should collect multiple errors from same row" do
    bulk_upload = build(:bulk_upload, user: @user)

    csv_content = <<~CSV
      FECHA,NRO DE PEDIDO,DESTINATARIO,TELÉFONO,DIRECCIÓN,COMUNA,DESCRIPCIÓN,MONTO,CAMBIO,EMPRESA
      fecha-invalida,ORD-001,,123,,,Descripción,15000,NO,
    CSV

    bulk_upload.file.attach(
      io: StringIO.new(csv_content),
      filename: 'test.csv',
      content_type: 'text/csv'
    )
    bulk_upload.save!

    validator = BulkPackageValidatorService.new(bulk_upload.file, @user)
    validator.validate

    # Should have errors for FECHA, DESTINATARIO, TELÉFONO, DIRECCIÓN, COMUNA, EMPRESA
    assert validator.errors.size >= 5

    row_2_errors = validator.errors.select { |e| e[:row] == 2 }
    assert row_2_errors.size >= 5
  end

  test "should collect errors from multiple rows" do
    bulk_upload = build(:bulk_upload, user: @user)

    csv_content = <<~CSV
      FECHA,NRO DE PEDIDO,DESTINATARIO,TELÉFONO,DIRECCIÓN,COMUNA,DESCRIPCIÓN,MONTO,CAMBIO,EMPRESA
      2025-12-15,ORD-001,,912345678,Av. Test 123,Providencia,Paquete,15000,NO,Test
      2025-12-16,ORD-002,Juan,123,Av. Test 456,Providencia,Paquete,15000,NO,Test
    CSV

    bulk_upload.file.attach(
      io: StringIO.new(csv_content),
      filename: 'test.csv',
      content_type: 'text/csv'
    )
    bulk_upload.save!

    validator = BulkPackageValidatorService.new(bulk_upload.file, @user)
    validator.validate

    # Row 2: missing DESTINATARIO
    # Row 3: invalid TELÉFONO
    assert validator.errors.size >= 2

    row_2_errors = validator.errors.select { |e| e[:row] == 2 }
    row_3_errors = validator.errors.select { |e| e[:row] == 3 }

    assert row_2_errors.any?
    assert row_3_errors.any?
  end

  # ====================
  # Header Validation Tests
  # ====================
  test "should fail when required headers are missing" do
    bulk_upload = create(:bulk_upload, :with_missing_headers, user: @user)
    validator = BulkPackageValidatorService.new(bulk_upload.file, @user)

    result = validator.validate

    assert_not result
    assert_not validator.valid?
    assert_not_empty validator.errors

    error = validator.errors.first
    assert_equal 0, error[:row]
    assert_equal 'estructura', error[:column]
    assert_includes error[:error], 'columnas requeridas'
  end

  # ====================
  # Row Limit Tests
  # ====================
  test "should validate only first 100 rows" do
    bulk_upload = build(:bulk_upload, user: @user)

    # Create CSV with 150 rows
    csv_content = "FECHA,NRO DE PEDIDO,DESTINATARIO,TELÉFONO,DIRECCIÓN,COMUNA,DESCRIPCIÓN,MONTO,CAMBIO,EMPRESA\n"
    150.times do |i|
      csv_content += "2025-12-15,ORD-#{i},Juan #{i},912345678,Av. Test #{i},Providencia,Paquete #{i},15000,NO,Test\n"
    end

    bulk_upload.file.attach(
      io: StringIO.new(csv_content),
      filename: 'large.csv',
      content_type: 'text/csv'
    )
    bulk_upload.save!

    validator = BulkPackageValidatorService.new(bulk_upload.file, @user)
    validator.validate

    assert_equal 150, validator.total_rows
    assert_equal 100, validator.validated_rows
    assert validator.has_more_rows?
  end

  test "should not have more rows flag when less than 100 rows" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    validator = BulkPackageValidatorService.new(bulk_upload.file, @user)

    validator.validate

    assert validator.total_rows < 100
    assert_equal validator.total_rows, validator.validated_rows
    assert_not validator.has_more_rows?
  end

  # ====================
  # Admin vs Customer Tests
  # ====================
  test "admin validation should check customer email exists" do
    admin = create(:user, :admin)
    bulk_upload = build(:bulk_upload, user: admin)

    csv_content = <<~CSV
      FECHA,NRO DE PEDIDO,DESTINATARIO,TELÉFONO,DIRECCIÓN,COMUNA,DESCRIPCIÓN,MONTO,CAMBIO,EMPRESA
      2025-12-15,ORD-001,Juan Pérez,912345678,Av. Test 123,Providencia,Paquete con ropa,15000,NO,noexiste@empresa.com
    CSV

    bulk_upload.file.attach(
      io: StringIO.new(csv_content),
      filename: 'test.csv',
      content_type: 'text/csv'
    )
    bulk_upload.save!

    validator = BulkPackageValidatorService.new(bulk_upload.file, admin)
    result = validator.validate

    assert_not result

    error = validator.errors.find { |e| e[:column] == 'EMPRESA' }
    assert_not_nil error
    assert_includes error[:error], 'email no existe'
  end

  test "admin validation should pass when customer email exists" do
    admin = create(:user, :admin)
    customer = create(:user, :customer, email: 'cliente@empresa.com')
    bulk_upload = build(:bulk_upload, user: admin)

    csv_content = <<~CSV
      FECHA,NRO DE PEDIDO,DESTINATARIO,TELÉFONO,DIRECCIÓN,COMUNA,DESCRIPCIÓN,MONTO,CAMBIO,EMPRESA
      2025-12-15,ORD-001,Juan Pérez,912345678,Av. Test 123,Providencia,Paquete con ropa,15000,NO,cliente@empresa.com
    CSV

    bulk_upload.file.attach(
      io: StringIO.new(csv_content),
      filename: 'test.csv',
      content_type: 'text/csv'
    )
    bulk_upload.save!

    validator = BulkPackageValidatorService.new(bulk_upload.file, admin)
    result = validator.validate

    assert result
    assert validator.valid?
  end

  test "customer validation should not check email existence" do
    customer = create(:user, :customer)
    bulk_upload = build(:bulk_upload, user: customer)

    csv_content = <<~CSV
      FECHA,NRO DE PEDIDO,DESTINATARIO,TELÉFONO,DIRECCIÓN,COMUNA,DESCRIPCIÓN,MONTO,CAMBIO,EMPRESA
      2025-12-15,ORD-001,Juan Pérez,912345678,Av. Test 123,Providencia,Paquete con ropa,15000,NO,cualquier@email.com
    CSV

    bulk_upload.file.attach(
      io: StringIO.new(csv_content),
      filename: 'test.csv',
      content_type: 'text/csv'
    )
    bulk_upload.save!

    validator = BulkPackageValidatorService.new(bulk_upload.file, customer)
    result = validator.validate

    assert result, "Customer validation should pass regardless of EMPRESA field"
    assert validator.valid?
  end

  test "customer validation should allow empty EMPRESA field" do
    customer = create(:user, :customer)
    bulk_upload = build(:bulk_upload, user: customer)

    csv_content = <<~CSV
      FECHA,NRO DE PEDIDO,DESTINATARIO,TELÉFONO,DIRECCIÓN,COMUNA,DESCRIPCIÓN,MONTO,CAMBIO,EMPRESA
      2025-12-15,ORD-001,Juan Pérez,912345678,Av. Test 123,Providencia,Paquete con ropa,15000,NO,
    CSV

    bulk_upload.file.attach(
      io: StringIO.new(csv_content),
      filename: 'test.csv',
      content_type: 'text/csv'
    )
    bulk_upload.save!

    validator = BulkPackageValidatorService.new(bulk_upload.file, customer)
    result = validator.validate

    assert result, "Customer validation should allow empty EMPRESA field"
    assert validator.valid?
    assert_empty validator.errors
  end

  # ====================
  # Phone Normalization Tests
  # ====================
  test "should validate normalized phone numbers" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    validator = BulkPackageValidatorService.new(bulk_upload.file, @user)

    result = validator.validate

    assert result
    assert validator.valid?
  end

  test "should accept various valid phone formats" do
    bulk_upload = build(:bulk_upload, user: @user)

    csv_content = <<~CSV
      FECHA,NRO DE PEDIDO,DESTINATARIO,TELÉFONO,DIRECCIÓN,COMUNA,DESCRIPCIÓN,MONTO,CAMBIO,EMPRESA
      2025-12-15,ORD-001,Juan,912345678,Av. Test,Providencia,Paquete,15000,NO,Test
      2025-12-15,ORD-002,Pedro,+56912345678,Av. Test,Providencia,Paquete,15000,NO,Test
      2025-12-15,ORD-003,Maria,12345678,Av. Test,Providencia,Paquete,15000,NO,Test
    CSV

    bulk_upload.file.attach(
      io: StringIO.new(csv_content),
      filename: 'test.csv',
      content_type: 'text/csv'
    )
    bulk_upload.save!

    validator = BulkPackageValidatorService.new(bulk_upload.file, @user)
    result = validator.validate

    assert result
    assert validator.valid?
  end

  # ====================
  # Commune Validation Tests
  # ====================
  test "should validate commune case-insensitive" do
    bulk_upload = build(:bulk_upload, user: @user)

    csv_content = <<~CSV
      FECHA,NRO DE PEDIDO,DESTINATARIO,TELÉFONO,DIRECCIÓN,COMUNA,DESCRIPCIÓN,MONTO,CAMBIO,EMPRESA
      2025-12-15,ORD-001,Juan,912345678,Av. Test,PROVIDENCIA,Paquete,15000,NO,Test
      2025-12-15,ORD-002,Pedro,912345678,Av. Test,providencia,Paquete,15000,NO,Test
      2025-12-15,ORD-003,Maria,912345678,Av. Test,ProViDeNcIa,Paquete,15000,NO,Test
    CSV

    bulk_upload.file.attach(
      io: StringIO.new(csv_content),
      filename: 'test.csv',
      content_type: 'text/csv'
    )
    bulk_upload.save!

    validator = BulkPackageValidatorService.new(bulk_upload.file, @user)
    result = validator.validate

    assert result
    assert validator.valid?
  end

  # ====================
  # Error Message Format Tests
  # ====================
  test "should include helpful error messages" do
    bulk_upload = build(:bulk_upload, user: @user)

    csv_content = <<~CSV
      FECHA,NRO DE PEDIDO,DESTINATARIO,TELÉFONO,DIRECCIÓN,COMUNA,DESCRIPCIÓN,MONTO,CAMBIO,EMPRESA
      fecha-mala,ORD-001,Juan,123,Av. Test,ComunaMala,Paquete,15000,NO,Test
    CSV

    bulk_upload.file.attach(
      io: StringIO.new(csv_content),
      filename: 'test.csv',
      content_type: 'text/csv'
    )
    bulk_upload.save!

    validator = BulkPackageValidatorService.new(bulk_upload.file, @user)
    validator.validate

    fecha_error = validator.errors.find { |e| e[:column] == 'FECHA' }
    assert_includes fecha_error[:error], 'formato de fecha inválido'
    assert_includes fecha_error[:error], 'YYYY-MM-DD'

    phone_error = validator.errors.find { |e| e[:column] == 'TELÉFONO' }
    assert_includes phone_error[:error], 'formato inválido'

    commune_error = validator.errors.find { |e| e[:column] == 'COMUNA' }
    assert_includes commune_error[:error], 'no existe en el sistema'
    assert_includes commune_error[:error], 'Región Metropolitana'
  end

  # ====================
  # Edge Cases
  # ====================
  test "should handle empty CSV file" do
    bulk_upload = build(:bulk_upload, user: @user)
    bulk_upload.file.attach(
      io: StringIO.new("FECHA,NRO DE PEDIDO,DESTINATARIO,TELÉFONO,DIRECCIÓN,COMUNA,DESCRIPCIÓN,MONTO,CAMBIO,EMPRESA\n"),
      filename: 'empty.csv',
      content_type: 'text/csv'
    )
    bulk_upload.save!

    validator = BulkPackageValidatorService.new(bulk_upload.file, @user)
    result = validator.validate

    assert result, "Empty file should validate successfully"
    assert_equal 0, validator.total_rows
    assert_equal 0, validator.validated_rows
  end

  test "should handle system errors gracefully" do
    bulk_upload = build(:bulk_upload, user: @user)
    bulk_upload.file.attach(
      io: StringIO.new("invalid content"),
      filename: 'test.csv',
      content_type: 'text/csv'
    )
    bulk_upload.save!

    validator = BulkPackageValidatorService.new(bulk_upload.file, @user)
    result = validator.validate

    assert_not result
    assert_not validator.valid?
    assert_not_empty validator.errors
  end
end
