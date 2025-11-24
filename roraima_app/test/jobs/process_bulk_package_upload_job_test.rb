require "test_helper"

class ProcessBulkPackageUploadJobTest < ActiveJob::TestCase
  setup do
    @user = create(:user, :customer)
    @region = Region.find_or_create_by!(name: 'Región Metropolitana')
    @providencia = Commune.find_or_create_by!(name: 'Providencia', region: @region)
    @las_condes = Commune.find_or_create_by!(name: 'Las Condes', region: @region)
    @la_florida = Commune.find_or_create_by!(name: 'La Florida', region: @region)
  end

  # ====================
  # Job Enqueuing Tests
  # ====================
  test "should be enqueued in bulk_uploads queue" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)

    assert_enqueued_with(job: ProcessBulkPackageUploadJob, args: [bulk_upload.id], queue: 'bulk_uploads') do
      ProcessBulkPackageUploadJob.perform_later(bulk_upload.id)
    end
  end

  # ====================
  # Successful Processing Tests
  # ====================
  test "should process bulk upload successfully" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)

    assert_difference 'Package.count', 3 do
      ProcessBulkPackageUploadJob.perform_now(bulk_upload.id)
    end

    bulk_upload.reload
    assert bulk_upload.completed?
    assert_equal 3, bulk_upload.successful_rows
  end

  test "should call service to process" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)

    # Mock the service
    service_mock = Minitest::Mock.new
    service_mock.expect :process, true

    BulkPackageUploadService.stub :new, service_mock do
      ProcessBulkPackageUploadJob.perform_now(bulk_upload.id)
    end

    service_mock.verify
  end

  # ====================
  # Error Handling Tests
  # ====================
  test "should handle BulkUpload not found" do
    non_existent_id = 999999

    assert_raises ActiveRecord::RecordNotFound do
      ProcessBulkPackageUploadJob.perform_now(non_existent_id)
    end
  end

  test "should mark as failed on exception" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)

    # Stub service to raise an exception
    BulkPackageUploadService.stub :new, -> (_) { raise StandardError.new("Test error") } do
      assert_raises StandardError do
        ProcessBulkPackageUploadJob.perform_now(bulk_upload.id)
      end
    end

    bulk_upload.reload
    assert bulk_upload.failed?
    assert_not_empty bulk_upload.error_details
    assert_includes bulk_upload.error_details.first['error'], "Test error"
  end

  # ====================
  # Logging Tests
  # ====================
  test "should log successful processing" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)

    # Capture Rails logger output
    log_output = StringIO.new
    old_logger = Rails.logger
    Rails.logger = Logger.new(log_output)

    ProcessBulkPackageUploadJob.perform_now(bulk_upload.id)

    Rails.logger = old_logger

    log_content = log_output.string
    assert_includes log_content, "Iniciando procesamiento de BulkUpload"
    assert_includes log_content, "procesado exitosamente"
  end

  test "should log errors" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)

    # Stub service to fail
    service_mock = Minitest::Mock.new
    service_mock.expect :process, false
    service_mock.expect :errors, [{ row: 1, error: 'test error' }]

    log_output = StringIO.new
    old_logger = Rails.logger
    Rails.logger = Logger.new(log_output)

    BulkPackageUploadService.stub :new, service_mock do
      ProcessBulkPackageUploadJob.perform_now(bulk_upload.id)
    end

    Rails.logger = old_logger

    log_content = log_output.string
    assert_includes log_content, "falló"

    service_mock.verify
  end

  # ====================
  # Retry Tests
  # ====================
  test "job should be configured with retry" do
    # Check that the job has retry_on configured
    assert ProcessBulkPackageUploadJob.retry_on_options.any? { |opts|
      opts[:exception] == StandardError
    }, "Job should have retry configuration for StandardError"
  end

  # ====================
  # Integration Tests
  # ====================
  test "should process complete workflow" do
    bulk_upload = create(:bulk_upload, :with_csv, user: @user)

    assert bulk_upload.pending?

    assert_difference 'Package.count', 3 do
      perform_enqueued_jobs do
        ProcessBulkPackageUploadJob.perform_later(bulk_upload.id)
      end
    end

    bulk_upload.reload

    assert bulk_upload.completed?
    assert_equal 3, bulk_upload.total_rows
    assert_equal 3, bulk_upload.successful_rows
    assert_equal 0, bulk_upload.failed_rows
    assert_not_nil bulk_upload.processed_at
  end

  test "should handle partial success" do
    bulk_upload = create(:bulk_upload, :with_invalid_csv, user: @user)

    perform_enqueued_jobs do
      ProcessBulkPackageUploadJob.perform_later(bulk_upload.id)
    end

    bulk_upload.reload

    assert bulk_upload.completed?, "Should be completed even with errors"
    assert_equal 5, bulk_upload.total_rows
    assert bulk_upload.successful_rows > 0, "Should have some successful rows"
    assert bulk_upload.failed_rows > 0, "Should have some failed rows"
    assert_not_empty bulk_upload.error_details
  end

  # ====================
  # Edge Cases
  # ====================
  test "should handle file with missing headers" do
    bulk_upload = create(:bulk_upload, :with_missing_headers, user: @user)

    assert_no_difference 'Package.count' do
      perform_enqueued_jobs do
        ProcessBulkPackageUploadJob.perform_later(bulk_upload.id)
      end
    end

    bulk_upload.reload

    assert bulk_upload.failed?
    assert_not_empty bulk_upload.error_details
  end

  test "should set processed_at even on failure" do
    bulk_upload = create(:bulk_upload, :with_missing_headers, user: @user)

    perform_enqueued_jobs do
      ProcessBulkPackageUploadJob.perform_later(bulk_upload.id)
    end

    bulk_upload.reload

    assert_not_nil bulk_upload.processed_at
  end
end
