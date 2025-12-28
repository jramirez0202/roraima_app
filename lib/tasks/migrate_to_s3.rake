# ActiveStorage Migration Tasks
# These tasks help migrate existing files from local Disk storage to Amazon S3

namespace :storage do
  desc "Migrate existing files from Disk to S3"
  task migrate_to_s3: :environment do
    puts "=" * 80
    puts "ActiveStorage Migration: Disk → S3"
    puts "=" * 80
    puts ""

    total = ActiveStorage::Blob.count
    migrated = 0
    skipped = 0
    errors = []

    if total.zero?
      puts "No files to migrate (ActiveStorage::Blob is empty)"
      next
    end

    puts "Found #{total} file(s) to process"
    puts ""

    ActiveStorage::Blob.find_each.with_index do |blob, index|
      begin
        # Check if already in S3
        if blob.service_name == 'amazon'
          skipped += 1
          puts "[#{index + 1}/#{total}] ⊘ Skipped: #{blob.filename} (already in S3)"
          next
        end

        # Get local file path
        local_service = ActiveStorage::Service.configure(:local, Rails.application.config.active_storage.service_configurations)
        file_path = local_service.path_for(blob.key)

        unless File.exist?(file_path)
          errors << { blob: blob.key, error: "Local file not found: #{file_path}" }
          puts "[#{index + 1}/#{total}] ✗ ERROR: #{blob.filename} - Local file not found"
          next
        end

        # Get S3 service
        s3_service = ActiveStorage::Service.configure(:amazon, Rails.application.config.active_storage.service_configurations)

        # Upload to S3
        File.open(file_path, 'rb') do |file|
          s3_service.upload(blob.key, file, checksum: blob.checksum)
        end

        # Verify checksum after upload
        s3_checksum = s3_service.send(:compute_checksum_in_chunks, s3_service.download(blob.key))

        if s3_checksum == blob.checksum
          migrated += 1
          file_size = ActiveSupport::NumberHelper.number_to_human_size(blob.byte_size)
          puts "[#{index + 1}/#{total}] ✓ Migrated: #{blob.filename} (#{file_size})"
        else
          errors << { blob: blob.key, error: "Checksum mismatch (local: #{blob.checksum}, s3: #{s3_checksum})" }
          puts "[#{index + 1}/#{total}] ✗ ERROR: #{blob.filename} - Checksum mismatch"
        end

      rescue => e
        errors << { blob: blob.key, error: e.message }
        puts "[#{index + 1}/#{total}] ✗ ERROR: #{blob.filename} - #{e.message}"
      end
    end

    # Summary
    puts ""
    puts "=" * 80
    puts "Migration Summary"
    puts "=" * 80
    puts "Total blobs:     #{total}"
    puts "Migrated:        #{migrated}"
    puts "Skipped:         #{skipped}"
    puts "Errors:          #{errors.size}"
    puts ""

    if errors.any?
      puts "=" * 80
      puts "Error Details"
      puts "=" * 80
      errors.each_with_index do |err, idx|
        puts "#{idx + 1}. Blob: #{err[:blob]}"
        puts "   Error: #{err[:error]}"
        puts ""
      end
    end

    if migrated == total - skipped
      puts "✓ Migration completed successfully!"
      puts ""
      puts "Next steps:"
      puts "1. Run 'rails storage:verify_s3' to verify all files"
      puts "2. Test your application thoroughly with S3 storage"
      puts "3. After 24-48 hours validation, switch to :amazon service in production.rb"
      puts "4. After 1 week, run 'rails storage:cleanup_disk' to free up local storage"
    else
      puts "⚠ Migration completed with errors. Please review and fix errors before proceeding."
    end

    puts ""
  end

  desc "Verify S3 migration integrity"
  task verify_s3: :environment do
    puts "=" * 80
    puts "S3 Migration Verification"
    puts "=" * 80
    puts ""

    s3_service = ActiveStorage::Service.configure(:amazon, Rails.application.config.active_storage.service_configurations)

    total = ActiveStorage::Blob.count
    verified = 0
    errors = []

    if total.zero?
      puts "No files to verify (ActiveStorage::Blob is empty)"
      next
    end

    puts "Verifying #{total} file(s)..."
    puts ""

    ActiveStorage::Blob.find_each.with_index do |blob, index|
      begin
        # Check if file exists in S3
        exists = s3_service.exist?(blob.key)

        unless exists
          errors << { blob: blob.key, filename: blob.filename.to_s, error: "File not found in S3" }
          puts "[#{index + 1}/#{total}] ✗ #{blob.filename} - NOT FOUND in S3"
          next
        end

        # Verify checksum
        s3_checksum = s3_service.send(:compute_checksum_in_chunks, s3_service.download(blob.key))
        checksum_match = s3_checksum == blob.checksum

        if checksum_match
          verified += 1
          file_size = ActiveSupport::NumberHelper.number_to_human_size(blob.byte_size)
          puts "[#{index + 1}/#{total}] ✓ #{blob.filename} (#{file_size})"
        else
          errors << { blob: blob.key, filename: blob.filename.to_s, error: "Checksum mismatch" }
          puts "[#{index + 1}/#{total}] ✗ #{blob.filename} - CHECKSUM MISMATCH"
        end

      rescue => e
        errors << { blob: blob.key, filename: blob.filename.to_s, error: e.message }
        puts "[#{index + 1}/#{total}] ✗ #{blob.filename} - ERROR: #{e.message}"
      end
    end

    # Summary
    puts ""
    puts "=" * 80
    puts "Verification Summary"
    puts "=" * 80
    puts "Total files:     #{total}"
    puts "Verified:        #{verified}"
    puts "Errors:          #{errors.size}"
    puts ""

    if errors.any?
      puts "=" * 80
      puts "Error Details"
      puts "=" * 80
      errors.each_with_index do |err, idx|
        puts "#{idx + 1}. File: #{err[:filename]}"
        puts "   Blob: #{err[:blob]}"
        puts "   Error: #{err[:error]}"
        puts ""
      end

      puts "⚠ Verification failed. Please fix errors before switching to :amazon service."
    else
      puts "✓ All files verified successfully in S3!"
      puts ""
      puts "You can now safely switch to :amazon service in config/environments/production.rb"
    end

    puts ""
  end

  desc "Cleanup local storage after S3 migration (DESTRUCTIVE)"
  task cleanup_disk: :environment do
    puts "=" * 80
    puts "⚠️  WARNING: Cleanup Local Storage"
    puts "=" * 80
    puts ""
    puts "This task will DELETE all files from local storage (/storage directory)"
    puts "Only run this after:"
    puts "  1. Successfully migrating to S3 (rails storage:migrate_to_s3)"
    puts "  2. Verifying S3 integrity (rails storage:verify_s3)"
    puts "  3. Running in production with :amazon service for at least 1 week"
    puts "  4. Confirming all features work correctly with S3"
    puts ""
    print "Are you absolutely sure you want to DELETE local storage? Type 'DELETE' to confirm: "

    response = STDIN.gets.chomp

    unless response == 'DELETE'
      puts ""
      puts "Cancelled. Local storage files preserved."
      puts ""
      next
    end

    puts ""
    puts "Starting cleanup..."
    puts ""

    deleted_count = 0
    errors = []
    total_size = 0

    ActiveStorage::Blob.find_each.with_index do |blob, index|
      begin
        # Construct local file path
        file_path = Rails.root.join("storage", *blob.key.scan(/../).first(2), blob.key)

        if File.exist?(file_path)
          file_size = File.size(file_path)
          File.delete(file_path)
          deleted_count += 1
          total_size += file_size

          human_size = ActiveSupport::NumberHelper.number_to_human_size(file_size)
          puts "[#{index + 1}] Deleted: #{blob.filename} (#{human_size})"
        else
          puts "[#{index + 1}] Skipped: #{blob.filename} (file not found locally)"
        end

      rescue => e
        errors << { blob: blob.key, filename: blob.filename.to_s, error: e.message }
        puts "[#{index + 1}] ERROR: #{blob.filename} - #{e.message}"
      end
    end

    # Clean up empty directories
    puts ""
    puts "Cleaning up empty directories..."

    storage_path = Rails.root.join("storage")
    Dir.glob(File.join(storage_path, "*", "*")).each do |dir|
      begin
        Dir.rmdir(dir) if Dir.empty?(dir)
      rescue
        # Ignore errors for non-empty directories
      end
    end

    Dir.glob(File.join(storage_path, "*")).each do |dir|
      begin
        Dir.rmdir(dir) if Dir.empty?(dir)
      rescue
        # Ignore errors for non-empty directories
      end
    end

    # Summary
    puts ""
    puts "=" * 80
    puts "Cleanup Summary"
    puts "=" * 80
    puts "Files deleted:   #{deleted_count}"
    puts "Space freed:     #{ActiveSupport::NumberHelper.number_to_human_size(total_size)}"
    puts "Errors:          #{errors.size}"
    puts ""

    if errors.any?
      puts "=" * 80
      puts "Error Details"
      puts "=" * 80
      errors.each_with_index do |err, idx|
        puts "#{idx + 1}. File: #{err[:filename]}"
        puts "   Error: #{err[:error]}"
        puts ""
      end
    end

    puts "✓ Local storage cleanup completed"
    puts ""
  end
end
