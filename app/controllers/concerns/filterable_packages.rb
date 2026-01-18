module FilterablePackages
  extend ActiveSupport::Concern

  # Aplica todos los filtros según params
  def apply_package_filters(base_scope)
    scope = base_scope

    # Filtro por estado
    if filter_params[:status].present? && Package.statuses.key?(filter_params[:status])
      scope = scope.where(status: filter_params[:status])
    end

    # Filtro por múltiples comunas
    if filter_params[:commune_ids].present?
      commune_ids = Array(filter_params[:commune_ids]).reject(&:blank?).map(&:to_i).select { |id| id > 0 }
      scope = scope.by_communes(commune_ids) if commune_ids.any?
    end

    # Filtro por múltiples drivers
    if filter_params[:courier_ids].present?
      courier_ids = Array(filter_params[:courier_ids]).reject(&:blank?).map(&:to_i).select { |id| id > 0 }
      scope = scope.by_couriers(courier_ids) if courier_ids.any?
    end

    # Filtro por múltiples customers
    if filter_params[:customer_ids].present?
      customer_ids = Array(filter_params[:customer_ids]).reject(&:blank?).map(&:to_i).select { |id| id > 0 }
      scope = scope.by_customers(customer_ids) if customer_ids.any?
    end

    # Búsqueda por tracking code
    searching_by_tracking = filter_params[:tracking_query].present?
    if searching_by_tracking
      scope = scope.search_by_tracking(filter_params[:tracking_query].strip)
    end

    # Rango de fechas - IMPORTANTE: Si busca por tracking, NO aplicar filtro de fecha por defecto
    if filter_params[:date_from].present? || filter_params[:date_to].present?
      # Usuario especificó fechas explícitamente, aplicar filtro
      date_from = parse_date(filter_params[:date_from])
      date_to = parse_date(filter_params[:date_to])

      # Si solo especifica "Desde" sin "Hasta", usar HOY como fecha final (o date_from si está en el futuro)
      if date_from.present? && date_to.nil?
        date_to = date_from > Date.current ? date_from : Date.current
      end

      # Si solo especifica "Hasta" sin "Desde", usar hace 3 días como fecha inicial
      date_from ||= Date.current - 2.days if date_to.present?

      # Validar que date_from <= date_to, si no, intercambiar
      if date_from && date_to && date_from > date_to
        date_from, date_to = date_to, date_from
      end

      scope = scope.activity_date_between(date_from, date_to)
    elsif !searching_by_tracking
      # Solo aplicar filtro por defecto si NO está buscando por tracking
      scope = scope.activity_date_between(Date.current - 2.days, Date.current)
    end
    # Si está buscando por tracking y no hay fechas explícitas, NO filtrar por fecha

    scope
  end

  # Construye hash de filtros activos para la vista
  def active_filters
    filters = {}
    filters[:status] = filter_params[:status] if filter_params[:status].present?

    if filter_params[:commune_ids].present?
      filters[:commune_ids] = Array(filter_params[:commune_ids]).reject(&:blank?).map(&:to_i)
    end

    if filter_params[:courier_ids].present?
      filters[:courier_ids] = Array(filter_params[:courier_ids]).reject(&:blank?).map(&:to_i)
    end

    if filter_params[:customer_ids].present?
      filters[:customer_ids] = Array(filter_params[:customer_ids]).reject(&:blank?).map(&:to_i)
    end

    filters[:tracking_query] = filter_params[:tracking_query].strip if filter_params[:tracking_query].present?
    filters[:date_from] = parse_date(filter_params[:date_from]) if filter_params[:date_from].present?
    filters[:date_to] = parse_date(filter_params[:date_to]) if filter_params[:date_to].present?

    filters
  end

  # Cuenta filtros activos
  def active_filters_count
    count = 0
    count += 1 if filter_params[:status].present?
    count += 1 if filter_params[:commune_ids].present? && Array(filter_params[:commune_ids]).reject(&:blank?).any?
    count += 1 if filter_params[:courier_ids].present? && Array(filter_params[:courier_ids]).reject(&:blank?).any?
    count += 1 if filter_params[:customer_ids].present? && Array(filter_params[:customer_ids]).reject(&:blank?).any?
    count += 1 if filter_params[:tracking_query].present?
    count += 1 if filter_params[:date_from].present? || filter_params[:date_to].present?
    count
  end

  private

  def filter_params
    # Permitir commune_ids, courier_ids y customer_ids tanto como scalar (autocomplete) como array (multi-select)
    @filter_params ||= begin
      permitted = params.permit(:status, :tracking_query, :date_from, :date_to, :page, :commune_ids, :courier_ids, :customer_ids, :button)

      # Normalizar commune_ids a array si viene como scalar
      if permitted[:commune_ids].present? && !permitted[:commune_ids].is_a?(Array)
        permitted[:commune_ids] = [permitted[:commune_ids]]
      end

      # Normalizar courier_ids a array si viene como scalar
      if permitted[:courier_ids].present? && !permitted[:courier_ids].is_a?(Array)
        permitted[:courier_ids] = [permitted[:courier_ids]]
      end

      # Normalizar customer_ids a array si viene como scalar
      if permitted[:customer_ids].present? && !permitted[:customer_ids].is_a?(Array)
        permitted[:customer_ids] = [permitted[:customer_ids]]
      end

      permitted
    end
  end

  def parse_date(date_string)
    return nil if date_string.blank?
    Date.parse(date_string)
  rescue ArgumentError, TypeError
    nil
  end
end
