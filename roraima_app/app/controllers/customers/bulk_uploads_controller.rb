module Customers
  class BulkUploadsController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_customer

    def new
      @bulk_upload = BulkUpload.new
    end

    def show
      @bulk_upload = current_user.bulk_uploads.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to customers_packages_path, alert: 'Carga masiva no encontrada'
    end

    def create
      @bulk_upload = current_user.bulk_uploads.build(bulk_upload_params)

      # Primero validar que el modelo sea válido (formato del archivo)
      unless @bulk_upload.valid?
        flash.now[:alert] = "Error al subir el archivo: #{@bulk_upload.errors.full_messages.join(', ')}"
        render :new, status: :unprocessable_entity
        return
      end

      # Guardar temporalmente para poder validar el contenido
      @bulk_upload.save!

      # Validar el contenido del archivo ANTES de encolar el job
      validator = BulkPackageValidatorService.new(@bulk_upload.file, current_user)

      if validator.validate
        # Si la validación pasó, encolar el job para procesamiento en background
        ProcessBulkPackageUploadJob.perform_later(@bulk_upload.id)

        redirect_to customers_bulk_upload_path(@bulk_upload),
                    notice: "✓ Carga iniciada. Procesando paquetes en segundo plano..."
      else
        # Si hay errores de validación, eliminar el BulkUpload y mostrar errores
        @bulk_upload.destroy

        @validation_errors = format_validation_errors(validator)
        flash.now[:alert] = "El archivo contiene errores de validación. Por favor corrígelos y vuelve a subir el archivo."
        render :new, status: :unprocessable_entity
      end
    end

    private

    def bulk_upload_params
      params.require(:bulk_upload).permit(:file)
    end

    def format_validation_errors(validator)
      errors = {
        total_rows: validator.total_rows,
        validated_rows: validator.validated_rows,
        has_more_rows: validator.has_more_rows?,
        error_list: []
      }

      validator.errors.each do |error|
        if error[:row] == 0
          # Error de estructura o sistema
          errors[:error_list] << "#{error[:column].upcase}: #{error[:error]}"
        else
          # Error de fila específica
          errors[:error_list] << "Fila #{error[:row]}: #{error[:column]} - #{error[:error]}"
        end
      end

      errors
    end

    def authorize_customer
      unless current_user.customer?
        redirect_to root_path, alert: 'No tienes permisos para acceder a esta sección'
      end
    end
  end
end
