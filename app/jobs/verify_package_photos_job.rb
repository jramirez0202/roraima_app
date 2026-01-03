# frozen_string_literal: true

# Background job para verificar que las fotos de evidencia estén en S3
# y confirmar la entrega automáticamente
class VerifyPackagePhotosJob < ApplicationJob
  queue_as :default

  def perform(package_id)
    package = Package.find(package_id)

    # Solo procesar si está pendiente de fotos
    return unless package.pending_photos?

    # Usar el servicio de upload para verificar y confirmar
    service = PackagePhotoUploadService.new(package, package.assigned_courier)

    if service.verify_and_confirm!
      Rails.logger.info "✅ Package #{package.tracking_code} photos verified and delivery confirmed"
    else
      Rails.logger.warn "⚠️ Verification failed for package #{package.tracking_code}: #{service.errors.join(', ')}"
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "❌ Package not found: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "❌ Error verifying photos for package #{package_id}: #{e.message}\n#{e.backtrace.join("\n")}"
    raise # Re-raise para que Sidekiq pueda reintentar
  end
end
