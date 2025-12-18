# frozen_string_literal: true

module Drivers
  class PackagesController < BaseController
    include FilterablePackages

    before_action :set_package, only: [:show, :change_status]

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
      # IMPORTANTE: Los paquetes reprogramados deben aparecer SIEMPRE (sin importar assigned_at)
      if date_from.present? && date_to.present?
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
    end

    def show
      authorize @package
    end

    def change_status
      authorize @package, :change_status?

      service = PackageStatusService.new(@package, current_user)

      if service.change_status(
        params[:new_status],
        reason: params[:reason],
        location: params[:location],
        override: false,
        proof: params[:proof],
        motive: params[:reason]
      )
        # Adjuntar fotos de reprogramación si se proporcionaron
        if params[:new_status] == 'rescheduled' && params[:reschedule_photos].present?
          params[:reschedule_photos].each do |photo|
            @package.reschedule_photos.attach(photo)
          end
        end

        redirect_to drivers_package_path(@package),
                    notice: 'Estado actualizado correctamente'
      else
        redirect_to drivers_package_path(@package),
                    alert: service.errors.join(', ')
      end
    end

    private

    def set_package
      @package = current_driver.visible_packages.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to drivers_packages_path, alert: 'Paquete no encontrado o no asignado'
    end
  end
end
