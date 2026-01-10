# frozen_string_literal: true

module Drivers
  class PackagesController < BaseController
    include FilterablePackages
    helper PackagesHelper

    before_action :set_package, only: [:show, :change_status, :update, :update_payment_method]

    def index
      # Nota: Drivers filtran por assigned_at (fecha de asignación), no por loading_date
      # Por eso no usamos el filtro de fecha del concern FilterablePackages

      # Parsear rango de fechas de asignación
      date_from = parse_date(filter_params[:date_from])
      date_to = parse_date(filter_params[:date_to])

      # Lógica de fechas por defecto (solo día actual si no se especifica)
      searching_by_tracking = filter_params[:tracking_query].present?

      if date_from.present? || date_to.present?
        # Usuario especificó fechas explícitamente
        date_to ||= Date.current if date_from.present?
        date_from ||= Date.current if date_to.present?
      elsif !searching_by_tracking
        # Solo aplicar filtro por defecto si NO está buscando por tracking
        date_from = Date.current
        date_to = Date.current
      end
      # Si está buscando por tracking y no hay fechas explícitas, NO filtrar por fecha

      @packages = policy_scope(Package)
                    .includes(:region, :commune)
                    .order(
                      Arel.sql("CASE WHEN status = #{Package.statuses[:rescheduled]} THEN 0 ELSE 1 END"),
                      Arel.sql("CASE WHEN status = #{Package.statuses[:rescheduled]} THEN assigned_at ELSE NULL END ASC"),
                      assigned_at: :desc
                    )

      # Aplicar filtro por rango de fechas de asignación (si aplica)
      # IMPORTANTE:
      # - Los paquetes reprogramados deben aparecer SIEMPRE (sin importar assigned_at)
      # - NO aplicar filtro de fecha si se está buscando por tracking code
      if date_from.present? && date_to.present? && !searching_by_tracking
        @packages = @packages.where(
          'assigned_at BETWEEN ? AND ? OR status = ?',
          date_from.beginning_of_day,
          date_to.end_of_day,
          Package.statuses[:rescheduled]
        )
      end

      # Aplicar filtro por estado
      if filter_params[:status].present? && Package.statuses.key?(filter_params[:status])
        @packages = @packages.where(status: filter_params[:status])
      end

      # Aplicar filtro de tracking code
      if searching_by_tracking
        @packages = @packages.search_by_tracking(filter_params[:tracking_query].strip)
      end

      # Status counters for the date range (usar date_from si está disponible, si no Date.current)
      counter_date = date_from || Date.current
      @status_counters = current_driver.status_summary(counter_date)

      # Variable para la vista (mostrar fecha del filtro)
      @filter_date = date_from || Date.current

      # Datos para filtros
      @active_filters = {
        status: filter_params[:status],
        tracking_query: filter_params[:tracking_query],
        date_from: date_from,
        date_to: date_to
      }.compact

      @active_filters_count = 0
      @active_filters_count += 1 if filter_params[:status].present?
      @active_filters_count += 1 if filter_params[:tracking_query].present?
      @active_filters_count += 1 if date_from.present? || date_to.present?

      @filtered_count = @packages.count
      @total_count = policy_scope(Package).count

      # Preservar parámetros de filtro para links a show
      @filter_params = @active_filters
    end

    def show
      authorize @package

      # Preservar parámetros de filtro para el botón "Volver"
      @filter_params = {
        status: params[:status],
        tracking_query: params[:tracking_query],
        commune_id: params[:commune_id],
        date_from: params[:date_from],
        date_to: params[:date_to]
      }.compact
    end

    def update
      authorize @package

      if @package.update(receiver_params)
        redirect_to drivers_package_path(@package),
                    notice: 'Detalles del receptor actualizados correctamente'
      else
        redirect_to drivers_package_path(@package),
                    alert: @package.errors.full_messages.join(', ')
      end
    end

    def change_status
      authorize @package, :change_status?

      # Validar cantidad de fotos ANTES de la transacción
      if params[:new_status] == 'delivered'
        photo_ids = Array(params[:package][:proof_photos]).compact.reject(&:blank?)
        if photo_ids.size < 1
          redirect_to drivers_package_path(@package), alert: "Se requiere al menos 1 foto de evidencia."
          return
        end
        if photo_ids.size > 4
          redirect_to drivers_package_path(@package), alert: "Máximo 4 fotos permitidas."
          return
        end

        # Validar que se haya enviado el nombre del receptor
        unless params[:receiver_name].present?
          redirect_to drivers_package_path(@package), alert: "Se requiere el nombre del receptor para marcar como entregado."
          return
        end
      end

      if params[:new_status] == 'rescheduled'
        photo_ids = Array(params[:reschedule_photos]).compact.reject(&:blank?)
        if photo_ids.size < 1
          redirect_to drivers_package_path(@package), alert: "Se requiere al menos 1 foto de evidencia para reprogramación."
          return
        end
        if photo_ids.size > 4
          redirect_to drivers_package_path(@package), alert: "Máximo 4 fotos permitidas."
          return
        end
      end

      if params[:new_status] == 'cancelled'
        photo_ids = Array(params[:cancelled_photos]).compact.reject(&:blank?)
        if photo_ids.size < 1
          redirect_to drivers_package_path(@package), alert: "Se requiere al menos 1 foto de evidencia para cancelación."
          return
        end
        if photo_ids.size > 4
          redirect_to drivers_package_path(@package), alert: "Máximo 4 fotos permitidas."
          return
        end
      end

      # Usar transacción: si algo falla, TODO se revierte (incluyendo fotos)
      service_errors = nil
      ActiveRecord::Base.transaction do
        # Actualizar datos del receptor ANTES de cambiar estado (para validación)
        if params[:new_status] == 'delivered'
          @package.update!(
            receiver_name: params[:receiver_name],
            receiver_observations: params[:receiver_observations]
          )
        end

        # Adjuntar fotos según el estado
        if params[:new_status] == 'delivered'
          photo_ids = Array(params[:package][:proof_photos]).compact.reject(&:blank?)
          photo_ids.each { |signed_id| @package.proof_photos.attach(signed_id) }
        elsif params[:new_status] == 'rescheduled'
          photo_ids = Array(params[:reschedule_photos]).compact.reject(&:blank?)
          photo_ids.each { |signed_id| @package.reschedule_photos.attach(signed_id) }
        elsif params[:new_status] == 'cancelled'
          photo_ids = Array(params[:cancelled_photos]).compact.reject(&:blank?)
          photo_ids.each { |signed_id| @package.cancelled_photos.attach(signed_id) }
        end

        # Cambiar el estado
        service = PackageStatusService.new(@package, current_user)
        success = service.change_status(
          params[:new_status],
          reason: params[:reason],
          location: params[:location],
          override: false,
          proof: @package.proof_photos.attached? ? 'attached' : nil,
          motive: params[:reason]
        )

        unless success
          # Guardar errores antes de revertir
          service_errors = service.errors
          # Si falla, lanzar excepción para revertir la transacción
          raise ActiveRecord::Rollback
        end
      end

      # Verificar si el cambio fue exitoso (revisando el estado actual)
      @package.reload
      if @package.status == params[:new_status]
        redirect_to drivers_root_path, notice: 'Estado actualizado correctamente'
      else
        error_message = service_errors&.any? ? service_errors.join(', ') : 'No se pudo actualizar el estado. Intenta de nuevo.'
        redirect_to drivers_package_path(@package), alert: error_message
      end
    end

    def update_payment_method
      authorize @package, :change_status?

      # Solo permitir si el paquete tiene monto > 0 y no está entregado
      unless @package.amount > 0 && !@package.delivered?
        redirect_to drivers_package_path(@package), alert: 'No se puede cambiar el método de pago en este momento.'
        return
      end

      # Validar que se envió un método de pago válido
      unless params[:payment_method].present? && %w[cash transfer].include?(params[:payment_method])
        redirect_to drivers_package_path(@package), alert: 'Método de pago inválido.'
        return
      end

      if @package.update(payment_method: params[:payment_method])
        redirect_to drivers_package_path(@package), notice: "Método de pago actualizado a #{helpers.payment_method_text(@package.payment_method)}."
      else
        redirect_to drivers_package_path(@package), alert: 'No se pudo actualizar el método de pago.'
      end
    end

    private

    def set_package
      @package = current_driver.visible_packages
                                .includes(
                                  :region,
                                  :commune,
                                  :user,
                                  :assigned_courier,
                                  :assigned_by,
                                  proof_photos_attachments: :blob,
                                  reschedule_photos_attachments: :blob,
                                  cancelled_photos_attachments: :blob
                                )
                                .find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to drivers_packages_path, alert: 'Paquete no encontrado o no asignado'
    end

    def receiver_params
      params.require(:package).permit(:receiver_name, :receiver_observations)
    end
  end
end
