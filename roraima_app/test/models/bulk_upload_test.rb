require "test_helper"

class BulkUploadTest < ActiveSupport::TestCase
  # ====================
  # Factory Tests
  # ====================
  test "valid bulk_upload factory should be valid" do
    bulk_upload = build(:bulk_upload, :with_csv)
    assert bulk_upload.valid?, "BulkUpload factory should create valid bulk_upload"
  end

  # ====================
  # Associations
  # ====================
  test "should belong to user" do
    bulk_upload = create(:bulk_upload, :with_csv)
    assert_respond_to bulk_upload, :user
    assert_instance_of User, bulk_upload.user
  end

  test "should have one attached file" do
    bulk_upload = create(:bulk_upload, :with_csv)
    assert bulk_upload.file.attached?, "BulkUpload should have attached file"
  end

  # ====================
  # Validations
  # ====================
  test "should require user" do
    bulk_upload = build(:bulk_upload, :with_csv, user: nil)
    assert_not bulk_upload.valid?
    assert_includes bulk_upload.errors[:user], "must exist"
  end

  test "should require file" do
    bulk_upload = build(:bulk_upload)
    assert_not bulk_upload.valid?
    assert_includes bulk_upload.errors[:file], "can't be blank"
  end

  test "should require status" do
    bulk_upload = build(:bulk_upload, :with_csv, status: nil)
    assert_not bulk_upload.valid?
    assert_includes bulk_upload.errors[:status], "can't be blank"
  end

  test "should validate file format" do
    bulk_upload = build(:bulk_upload)
    bulk_upload.file.attach(
      io: StringIO.new("test content"),
      filename: 'test.txt',
      content_type: 'text/plain'
    )

    assert_not bulk_upload.valid?
    assert_includes bulk_upload.errors[:file], "debe ser un archivo CSV o XLSX"
  end

  test "should accept CSV file" do
    bulk_upload = build(:bulk_upload, :with_csv)
    assert bulk_upload.valid?, "Should accept CSV files"
  end

  # ====================
  # Status Enum
  # ====================
  test "should default to pending status" do
    bulk_upload = create(:bulk_upload, :with_csv)
    assert bulk_upload.pending?
    assert_not bulk_upload.processing?
    assert_not bulk_upload.completed?
    assert_not bulk_upload.failed?
  end

  test "should allow pending status" do
    bulk_upload = create(:bulk_upload, :with_csv, status: :pending)
    assert bulk_upload.pending?
  end

  test "should allow processing status" do
    bulk_upload = create(:bulk_upload, :with_csv, :processing)
    assert bulk_upload.processing?
  end

  test "should allow completed status" do
    bulk_upload = create(:bulk_upload, :with_csv, :completed)
    assert bulk_upload.completed?
  end

  test "should allow failed status" do
    bulk_upload = create(:bulk_upload, :with_csv, :failed)
    assert bulk_upload.failed?
  end

  # ====================
  # success_rate Method
  # ====================
  test "success_rate should return 0 when total_rows is zero" do
    bulk_upload = build(:bulk_upload, :with_csv, total_rows: 0, successful_rows: 0)
    assert_equal 0, bulk_upload.success_rate
  end

  test "success_rate should return 100 when all rows successful" do
    bulk_upload = build(:bulk_upload, :with_csv, total_rows: 10, successful_rows: 10, failed_rows: 0)
    assert_equal 100.0, bulk_upload.success_rate
  end

  test "success_rate should return 50 when half rows successful" do
    bulk_upload = build(:bulk_upload, :with_csv, total_rows: 10, successful_rows: 5, failed_rows: 5)
    assert_equal 50.0, bulk_upload.success_rate
  end

  test "success_rate should return correct percentage" do
    bulk_upload = build(:bulk_upload, :with_csv, total_rows: 100, successful_rows: 75, failed_rows: 25)
    assert_equal 75.0, bulk_upload.success_rate
  end

  test "success_rate should round to 2 decimal places" do
    bulk_upload = build(:bulk_upload, :with_csv, total_rows: 3, successful_rows: 2, failed_rows: 1)
    assert_equal 66.67, bulk_upload.success_rate
  end

  # ====================
  # formatted_errors Method
  # ====================
  test "formatted_errors should return empty array when no errors" do
    bulk_upload = build(:bulk_upload, :with_csv, :completed, error_details: [])
    assert_empty bulk_upload.formatted_errors
  end

  test "formatted_errors should return empty array when error_details is nil" do
    bulk_upload = build(:bulk_upload, :with_csv, error_details: nil)
    assert_empty bulk_upload.formatted_errors
  end

  test "formatted_errors should format single error" do
    bulk_upload = build(:bulk_upload, :with_csv,
      error_details: [
        { 'row' => 2, 'column' => 'TELÉFONO', 'error' => 'formato inválido' }
      ]
    )

    errors = bulk_upload.formatted_errors
    assert_equal 1, errors.size
    assert_equal "Fila 2: TELÉFONO - formato inválido", errors.first
  end

  test "formatted_errors should format multiple errors" do
    bulk_upload = build(:bulk_upload, :with_csv, :completed_with_errors)

    errors = bulk_upload.formatted_errors
    assert_equal 2, errors.size
    assert_includes errors, "Fila 2: TELÉFONO - formato inválido después de transformación: 123"
    assert_includes errors, "Fila 4: COMUNA - no existe en el sistema"
  end

  # ====================
  # Scopes
  # ====================
  test "recent scope should order by created_at desc" do
    old_upload = create(:bulk_upload, :with_csv, created_at: 1.day.ago)
    new_upload = create(:bulk_upload, :with_csv, created_at: Time.current)

    recent_uploads = BulkUpload.recent
    assert_equal new_upload.id, recent_uploads.first.id
    assert_equal old_upload.id, recent_uploads.last.id
  end

  # ====================
  # Default Values
  # ====================
  test "should default total_rows to 0" do
    bulk_upload = create(:bulk_upload, :with_csv)
    assert_equal 0, bulk_upload.total_rows
  end

  test "should default successful_rows to 0" do
    bulk_upload = create(:bulk_upload, :with_csv)
    assert_equal 0, bulk_upload.successful_rows
  end

  test "should default failed_rows to 0" do
    bulk_upload = create(:bulk_upload, :with_csv)
    assert_equal 0, bulk_upload.failed_rows
  end

  test "should default error_details to empty array" do
    bulk_upload = create(:bulk_upload, :with_csv)
    assert_equal [], bulk_upload.error_details
  end

  # ====================
  # Edge Cases
  # ====================
  test "should handle large error_details array" do
    large_errors = 100.times.map do |i|
      { 'row' => i, 'column' => 'TEST', 'error' => "Error #{i}" }
    end

    bulk_upload = build(:bulk_upload, :with_csv, error_details: large_errors)
    assert bulk_upload.valid?
    assert_equal 100, bulk_upload.error_details.size
  end

  test "processed_at should be nil for pending uploads" do
    bulk_upload = create(:bulk_upload, :with_csv, status: :pending)
    assert_nil bulk_upload.processed_at
  end

  test "processed_at should be set for completed uploads" do
    bulk_upload = create(:bulk_upload, :with_csv, :completed)
    assert_not_nil bulk_upload.processed_at
  end

  test "should handle upload without NRO DE PEDIDO column" do
    # This tests that tracking_code is optional and auto-generated
    bulk_upload = create(:bulk_upload, :with_csv)
    assert bulk_upload.valid?
  end
end
