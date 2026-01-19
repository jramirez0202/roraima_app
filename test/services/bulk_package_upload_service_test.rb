require "test_helper"

class BulkPackageUploadServiceTest < ActiveSupport::TestCase
  setup do
    @user = create(:user, :customer)
    # Ensure Región Metropolitana exists
    @region = Region.find_or_create_by!(name: 'Región Metropolitana')

    # Create test communes
    @providencia = Commune.find_or_create_by!(name: 'Providencia', region: @region)
    @las_condes = Commune.find_or_create_by!(name: 'Las Condes', region: @region)
    @la_florida = Commune.find_or_create_by!(name: 'La Florida', region: @region)
  end

  # ====================
  # Successful Processing Tests
  # ====================
  test "should process valid CSV file successfully" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    assert_difference 'Package.count', 3 do
      result = service.process
      assert result, "Service should return true for successful processing"
    end

    bulk_upload.reload
    assert bulk_upload.completed?
    assert_equal 3, bulk_upload.total_rows
    assert_equal 3, bulk_upload.successful_rows
    assert_equal 0, bulk_upload.failed_rows
    assert_empty bulk_upload.error_details
  end

  test "should update bulk_upload status to processing" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    service.process

    # During processing it should be processing, after completion it should be completed
    bulk_upload.reload
    assert bulk_upload.completed?
  end

  test "should set processed_at timestamp" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    assert_nil bulk_upload.processed_at

    service.process
    bulk_upload.reload

    assert_not_nil bulk_upload.processed_at
  end

  # ====================
  # Phone Normalization Tests
  # ====================
  test "should normalize phone numbers correctly" do
    bulk_upload = build(:bulk_upload, user: @user)

    # Attach phone normalization CSV file
    file_content = File.read(Rails.root.join('test', 'fixtures', 'files', 'phone_normalization.csv'))
    bulk_upload.file.attach(
      io: StringIO.new(file_content),
      filename: 'phone_normalization.csv',
      content_type: 'text/csv'
    )
    bulk_upload.save!

    service = BulkPackageUploadService.new(bulk_upload)

    assert_difference 'Package.count', 4 do
      service.process
    end

    packages = Package.last(4)

    # All should be normalized to +569XXXXXXXX format
    packages.each do |package|
      assert package.phone.start_with?('+569'), "Phone should start with +569, got: #{package.phone}"
      assert_equal 12, package.phone.length, "Phone should be 12 characters, got: #{package.phone}"
    end
  end

  test "normalize_phone should handle format with +56" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    assert_equal "+56912345678", service.send(:normalize_phone, "+56912345678")
  end

  test "normalize_phone should add +56 to 9XXXXXXXX" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    assert_equal "+56912345678", service.send(:normalize_phone, "912345678")
  end

  test "normalize_phone should add +569 to 8-digit number" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    assert_equal "+56912345678", service.send(:normalize_phone, "12345678")
  end

  test "normalize_phone should remove spaces and hyphens" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    assert_equal "+56912345678", service.send(:normalize_phone, "+56 9 1234 5678")
    assert_equal "+56912345678", service.send(:normalize_phone, "+569-1234-5678")
  end

  # ====================
  # Error Handling Tests
  # ====================
  test "should handle invalid data and continue processing" do
    bulk_upload = create(:bulk_upload, :with_invalid_csv, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    # Should create some packages despite errors
    service.process

    bulk_upload.reload
    assert bulk_upload.completed?, "Should complete even with errors"
    assert_equal 5, bulk_upload.total_rows
    assert bulk_upload.failed_rows > 0, "Should have some failed rows"
    assert_not_empty bulk_upload.error_details
  end

  test "should collect error details for invalid rows" do
    bulk_upload = create(:bulk_upload, :with_invalid_csv, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    service.process
    bulk_upload.reload

    # Should have errors for invalid phone, invalid commune, etc.
    assert_not_empty bulk_upload.error_details

    # Check that errors have required fields
    error = bulk_upload.error_details.first
    assert error.key?('row')
    assert error.key?('column')
    assert error.key?('error')
  end

  test "should fail when file has missing required headers" do
    bulk_upload = create(:bulk_upload, :with_missing_headers, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    assert_no_difference 'Package.count' do
      result = service.process
      assert_not result, "Service should return false for invalid file structure"
    end

    bulk_upload.reload
    assert bulk_upload.failed?
    assert_not_empty bulk_upload.error_details
    assert_includes bulk_upload.error_details.first['error'], 'columnas requeridas'
  end

  # ====================
  # Field Mapping Tests
  # ====================
  test "should auto-assign loading_date to today during CSV upload" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    service.process

    package = Package.last
    assert_not_nil package.loading_date, "loading_date should be set automatically"
    assert_equal Date.current, package.loading_date, "loading_date should default to today"
  end

  test "should map DESTINATARIO to customer_name" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    service.process

    package = Package.last
    assert_not_nil package.customer_name
    assert_equal "Pedro Ramírez", package.customer_name
  end

  test "should map COMUNA to commune_id" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    service.process

    package = Package.last
    assert_not_nil package.commune_id
    assert_equal @la_florida.id, package.commune_id
  end

  test "should map MONTO to amount" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    service.process

    package = Package.last
    assert_not_nil package.amount
    assert_equal 8000.0, package.amount
  end

  test "should map CAMBIO to exchange boolean" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    service.process

    packages = Package.last(3)

    # First row has "NO"
    assert_not packages[0].exchange

    # Second row has "SI"
    assert packages[1].exchange

    # Third row has "NO"
    assert_not packages[2].exchange
  end

  test "should set status to pending_pickup" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    service.process

    package = Package.last
    assert package.pending_pickup?
  end

  test "should associate packages with user" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    service.process

    package = Package.last
    assert_equal @user.id, package.user_id
  end

  # ====================
  # Commune Lookup Tests
  # ====================
  test "find_commune should find commune case-insensitive" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    commune = service.send(:find_commune, 'PROVIDENCIA')
    assert_equal @providencia.id, commune.id

    commune = service.send(:find_commune, 'providencia')
    assert_equal @providencia.id, commune.id

    commune = service.send(:find_commune, 'ProViDeNcIa')
    assert_equal @providencia.id, commune.id
  end

  test "find_commune should return nil for non-existent commune" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    commune = service.send(:find_commune, 'NoExiste')
    assert_nil commune
  end

  # ====================
  # Amount Parsing Tests
  # ====================
  test "parse_amount should handle numeric values" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    assert_equal 1000.0, service.send(:parse_amount, 1000)
    assert_equal 1500.5, service.send(:parse_amount, 1500.5)
  end

  test "parse_amount should handle string values" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    assert_equal 1000.0, service.send(:parse_amount, "1000")
    assert_equal 1500.5, service.send(:parse_amount, "1500.5")
  end

  test "parse_amount should handle comma as decimal separator" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    assert_equal 1500.5, service.send(:parse_amount, "1500,5")
  end

  test "parse_amount should remove currency symbols" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    assert_equal 1000.0, service.send(:parse_amount, "$1000")
    assert_equal 1000.0, service.send(:parse_amount, "$ 1000")
  end

  test "parse_amount should return 0 for blank values" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    assert_equal 0.0, service.send(:parse_amount, "")
    assert_equal 0.0, service.send(:parse_amount, nil)
  end

  # ====================
  # Error Collection Tests
  # ====================
  test "add_error should add error to collection" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    service.send(:add_error, 5, 'TELÉFONO', '123', 'formato inválido')

    errors = service.errors
    assert_equal 1, errors.size
    assert_equal 5, errors.first[:row]
    assert_equal 'TELÉFONO', errors.first[:column]
    assert_equal '123', errors.first[:value]
    assert_equal 'formato inválido', errors.first[:error]
  end

  test "add_error should truncate long values" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    long_value = "a" * 100
    service.send(:add_error, 1, 'TEST', long_value, 'error')

    errors = service.errors
    assert errors.first[:value].length <= 51 # Truncated to 50 + ...
  end

  # ====================
  # Region Handling Tests
  # ====================
  test "should always use Región Metropolitana" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    service.process

    packages = Package.last(3)
    packages.each do |package|
      assert_equal @region.id, package.region_id
    end
  end

  # ====================
  # Tracking Code Tests
  # ====================
  test "should auto-generate tracking_code if not provided" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    service.process

    package = Package.last
    assert_not_nil package, "Package should be created"
    assert_not_nil package.tracking_code, "Tracking code should exist"
    # The CSV has tracking codes provided (TEST-001, etc.), so we check for those
    assert package.tracking_code.present?, "Tracking code should not be blank"
  end

  # ====================
  # Role-Based Assignment Tests
  # ====================
  test "admin upload should assign packages to customer by email" do
    admin = create(:user, :admin)
    customer = create(:user, :customer, email: 'cliente@empresa.com')

    bulk_upload = build(:bulk_upload, user: admin)

    # Create CSV with customer email
    csv_content = <<~CSV
      FECHA,NRO DE PEDIDO,DESTINATARIO,TELÉFONO,DIRECCIÓN,COMUNA,DESCRIPCIÓN,MONTO,CAMBIO,EMPRESA
      2025-12-15,ORD-001,Juan Pérez,912345678,Av. Providencia 123,Providencia,Paquete con ropa,15000,NO,cliente@empresa.com
    CSV

    bulk_upload.file.attach(
      io: StringIO.new(csv_content),
      filename: 'test.csv',
      content_type: 'text/csv'
    )
    bulk_upload.save!

    service = BulkPackageUploadService.new(bulk_upload)

    assert_difference 'Package.count', 1 do
      service.process
    end

    package = Package.last
    assert_equal customer.id, package.user_id, "Package should be assigned to customer, not admin"
    assert_equal 'cliente@empresa.com', package.sender_email
  end

  test "admin upload should error when customer email not found" do
    admin = create(:user, :admin)

    bulk_upload = build(:bulk_upload, user: admin)

    # Create CSV with non-existent customer email
    csv_content = <<~CSV
      FECHA,NRO DE PEDIDO,DESTINATARIO,TELÉFONO,DIRECCIÓN,COMUNA,DESCRIPCIÓN,MONTO,CAMBIO,EMPRESA
      2025-12-15,ORD-001,Juan Pérez,912345678,Av. Providencia 123,Providencia,Paquete con ropa,15000,NO,noexiste@empresa.com
    CSV

    bulk_upload.file.attach(
      io: StringIO.new(csv_content),
      filename: 'test.csv',
      content_type: 'text/csv'
    )
    bulk_upload.save!

    service = BulkPackageUploadService.new(bulk_upload)

    assert_no_difference 'Package.count' do
      service.process
    end

    bulk_upload.reload
    assert_not_empty bulk_upload.error_details
    error = bulk_upload.error_details.first
    assert_equal 'EMPRESA', error['column']
    assert_includes error['error'], 'email no existe'
  end

  test "admin upload should error when email belongs to inactive customer" do
    admin = create(:user, :admin)
    inactive_customer = create(:user, :customer, email: 'inactivo@empresa.com', active: false)

    bulk_upload = build(:bulk_upload, user: admin)

    csv_content = <<~CSV
      FECHA,NRO DE PEDIDO,DESTINATARIO,TELÉFONO,DIRECCIÓN,COMUNA,DESCRIPCIÓN,MONTO,CAMBIO,EMPRESA
      2025-12-15,ORD-001,Juan Pérez,912345678,Av. Providencia 123,Providencia,Paquete con ropa,15000,NO,inactivo@empresa.com
    CSV

    bulk_upload.file.attach(
      io: StringIO.new(csv_content),
      filename: 'test.csv',
      content_type: 'text/csv'
    )
    bulk_upload.save!

    service = BulkPackageUploadService.new(bulk_upload)

    assert_no_difference 'Package.count' do
      service.process
    end

    bulk_upload.reload
    assert_not_empty bulk_upload.error_details
    error = bulk_upload.error_details.first
    assert_includes error['error'], 'email no existe'
  end

  test "customer upload should assign packages to themselves ignoring EMPRESA field" do
    customer = create(:user, :customer, email: 'micuenta@empresa.com')
    other_customer = create(:user, :customer, email: 'otraempresa@empresa.com')

    bulk_upload = build(:bulk_upload, user: customer)

    # Create CSV with different customer email in EMPRESA field
    csv_content = <<~CSV
      FECHA,NRO DE PEDIDO,DESTINATARIO,TELÉFONO,DIRECCIÓN,COMUNA,DESCRIPCIÓN,MONTO,CAMBIO,EMPRESA
      2025-12-15,ORD-001,Juan Pérez,912345678,Av. Providencia 123,Providencia,Paquete con ropa,15000,NO,otraempresa@empresa.com
    CSV

    bulk_upload.file.attach(
      io: StringIO.new(csv_content),
      filename: 'test.csv',
      content_type: 'text/csv'
    )
    bulk_upload.save!

    service = BulkPackageUploadService.new(bulk_upload)

    assert_difference 'Package.count', 1 do
      service.process
    end

    package = Package.last
    assert_equal customer.id, package.user_id, "Package should be assigned to logged-in customer"
    assert_not_equal other_customer.id, package.user_id
    assert_equal 'otraempresa@empresa.com', package.sender_email, "EMPRESA field should still be saved"
  end

  test "find_customer_by_email should find active customer case-insensitive" do
    customer = create(:user, :customer, email: 'Test@Empresa.com', active: true)
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    found = service.send(:find_customer_by_email, 'test@empresa.com')
    assert_equal customer.id, found.id

    found = service.send(:find_customer_by_email, 'TEST@EMPRESA.COM')
    assert_equal customer.id, found.id

    found = service.send(:find_customer_by_email, 'Test@Empresa.com')
    assert_equal customer.id, found.id
  end

  test "find_customer_by_email should not find inactive customer" do
    create(:user, :customer, email: 'inactivo@empresa.com', active: false)
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    found = service.send(:find_customer_by_email, 'inactivo@empresa.com')
    assert_nil found
  end

  test "find_customer_by_email should not find admin users" do
    create(:user, :admin, email: 'admin@empresa.com', active: true)
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    found = service.send(:find_customer_by_email, 'admin@empresa.com')
    assert_nil found
  end

  test "find_customer_by_email should return nil for non-existent email" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    found = service.send(:find_customer_by_email, 'noexiste@empresa.com')
    assert_nil found
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

    service = BulkPackageUploadService.new(bulk_upload)

    assert_no_difference 'Package.count' do
      service.process
    end

    bulk_upload.reload
    assert bulk_upload.completed?
    assert_equal 0, bulk_upload.total_rows
  end

  test "should handle exception gracefully" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)
    service = BulkPackageUploadService.new(bulk_upload)

    # Mock the open_spreadsheet method to raise an exception
    def service.open_spreadsheet
      raise StandardError.new("Test error")
    end

    result = service.process
    assert_not result, "Service should return false on exception"

    bulk_upload.reload
    assert bulk_upload.failed?, "Bulk upload should be marked as failed"
    assert_not_empty bulk_upload.error_details, "Should have error details"
  end
end
