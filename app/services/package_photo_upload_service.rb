# Servicio para manejar upload de fotos de paquetes con validación S3
class PackagePhotoUploadService
  attr_reader :package, :user, :errors

  MAX_PHOTOS = 4
  MIN_PHOTOS = 1
  ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/heic image/webp].freeze
  MAX_FILE_SIZE = 10.megabytes

  def initialize(package, user)
    @package = package
    @user = user
    @errors = []
  end

  # Adjunta fotos al paquete y valida
  def attach_photos(photos_params)
    photos = Array(photos_params).compact.reject(&:blank?)
    current_count = package.proof_photos.count

    # Validar límite
    if current_count + photos.size > MAX_PHOTOS
      @errors << "Máximo #{MAX_PHOTOS} fotos permitidas. Actualmente: #{current_count}, intentando agregar: #{photos.size}"
      return false
    end

    if photos.empty?
      @errors << "Debe proporcionar al menos una foto"
      return false
    end

    # Validar cada archivo
    return false unless photos.all? { |p| valid_photo?(p) }

    # Adjuntar fotos
    begin
      ActiveRecord::Base.transaction do
        photos.each { |photo| package.proof_photos.attach(photo) }
        package.update!(photos_uploaded_at: Time.current) if package.photos_uploaded_at.nil?
      end
      true
    rescue StandardError => e
      @errors << "Error al adjuntar fotos: #{e.message}"
      Rails.logger.error "PackagePhotoUploadService error: #{e.message}\n#{e.backtrace.join("\n")}"
      false
    end
  end

  # Verifica que las fotos estén en S3 y confirma la entrega
  def verify_and_confirm!
    unless package.proof_photos.attached? && package.proof_photos.count >= MIN_PHOTOS
      @errors << "Se requiere al menos #{MIN_PHOTOS} foto(s)"
      return false
    end

    # Verificar que todas las fotos existen en S3
    unless all_photos_in_storage?
      @errors << "No todas las fotos están disponibles en el almacenamiento"
      return false
    end

    # Confirmar entrega
    begin
      package.confirm_photos!
      Rails.logger.info "✅ Package #{package.tracking_code} photos confirmed, delivery completed"
      true
    rescue StandardError => e
      @errors << "Error al confirmar fotos: #{e.message}"
      Rails.logger.error "PackagePhotoUploadService confirmation error: #{e.message}"
      false
    end
  end

  # Obtiene el estado del upload de fotos
  def photo_status
    {
      total_photos: package.proof_photos.count,
      pending_photos: package.pending_photos?,
      photos_confirmed: package.photos_confirmed?,
      photos_uploaded_at: package.photos_uploaded_at,
      photos_confirmed_at: package.photos_confirmed_at,
      can_upload_more: package.proof_photos.count < MAX_PHOTOS,
      all_in_storage: all_photos_in_storage?
    }
  end

  private

  def valid_photo?(photo)
    # Validar tipo de contenido
    unless ALLOWED_CONTENT_TYPES.include?(photo.content_type)
      @errors << "Formato no permitido: #{photo.content_type}. Permitidos: #{ALLOWED_CONTENT_TYPES.join(', ')}"
      return false
    end

    # Validar tamaño
    if photo.size > MAX_FILE_SIZE
      size_mb = (photo.size.to_f / 1.megabyte).round(2)
      max_mb = (MAX_FILE_SIZE.to_f / 1.megabyte).round(2)
      @errors << "Archivo muy grande: #{size_mb}MB. Máximo: #{max_mb}MB"
      return false
    end

    true
  end

  def all_photos_in_storage?
    package.proof_photos.all? do |photo|
      photo.blob.service.exist?(photo.blob.key)
    end
  rescue StandardError => e
    Rails.logger.error "Error checking photo existence in S3: #{e.message}"
    false
  end
end
