class ProcessBulkPackageUploadJob < ApplicationJob
  queue_as :bulk_uploads

  # Reintentar hasta 3 veces con espera polinomial
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(bulk_upload_id)
    bulk_upload = BulkUpload.find(bulk_upload_id)

    Rails.logger.info "Iniciando procesamiento de BulkUpload ##{bulk_upload_id}"

    service = BulkPackageUploadService.new(bulk_upload)

    if service.process
      Rails.logger.info "BulkUpload ##{bulk_upload_id} procesado exitosamente. " \
                        "Total: #{bulk_upload.total_rows}, " \
                        "Exitosos: #{bulk_upload.successful_rows}, " \
                        "Fallidos: #{bulk_upload.failed_rows}"
    else
      Rails.logger.error "BulkUpload ##{bulk_upload_id} falló. Errores: #{service.errors.inspect}"
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "BulkUpload ##{bulk_upload_id} no encontrado: #{e.message}"
    raise # Re-lanzar para que Sidekiq lo maneje
  rescue => e
    Rails.logger.error "Error inesperado procesando BulkUpload ##{bulk_upload_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    # Marcar como fallido si existe
    if bulk_upload
      bulk_upload.update(
        status: :failed,
        error_details: [{ row: 0, column: 'sistema', value: '', error: "Error del sistema: #{e.message}" }],
        processed_at: Time.current
      )
    end

    raise # Re-lanzar para que Sidekiq lo maneje
  end
end
