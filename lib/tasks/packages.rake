# frozen_string_literal: true

namespace :packages do
  desc "Verify pending photos and confirm deliveries if S3 upload successful"
  task verify_pending_photos: :environment do
    packages = Package.pending_photo_upload.includes(:assigned_courier, :proof_photos_attachments)

    puts "📦 Found #{packages.count} packages with pending photos"

    packages.find_each do |package|
      VerifyPackagePhotosJob.perform_later(package.id)
      puts "  → Enqueued verification for #{package.tracking_code}"
    end

    puts "✅ Verification jobs enqueued"
  end

  desc "Show packages pending photos older than N hours (default 24)"
  task :pending_photos_report, [:hours] => :environment do |_t, args|
    hours = (args[:hours] || 24).to_i
    packages = Package.pending_photos_older_than(hours)
                      .includes(:assigned_courier)
                      .order(delivered_at: :asc)

    puts "\n📊 Packages pending photos for more than #{hours} hours\n"
    puts "=" * 80

    if packages.empty?
      puts "✅ No packages found"
    else
      packages.each do |pkg|
        age = ((Time.current - pkg.delivered_at) / 1.hour).round(1)
        driver = pkg.assigned_courier&.name || "N/A"
        puts "#{pkg.tracking_code} | #{driver} | #{age}h ago | Photos: #{pkg.proof_photos.count}"
      end
      puts "\n📦 Total: #{packages.count} packages"
    end

    puts "=" * 80
  end
end
