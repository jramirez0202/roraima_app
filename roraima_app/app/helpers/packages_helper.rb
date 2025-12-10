module PackagesHelper
  # Traducciones centralizadas de estados
  STATUS_TRANSLATIONS = {
    pending_pickup: "Pendiente Retiro",
    in_warehouse: "Bodega",
    in_transit: "En Camino",
    rescheduled: "Reprogramado",
    delivered: "Entregado",
    picked_up: "Retirado",
    return: "Devolución",
    cancelled: "Cancelado"
  }.freeze

  # Clases CSS para badges de estado
STATUS_BADGE_CLASSES = {
  pending_pickup: "bg-yellow-500 text-white",       # Pendiente
  in_warehouse:  "bg-blue-500 text-white",         # Bodega
  in_transit:    "bg-blue-600 text-white",         # En camino
  picked_up:     "bg-green-600 text-white",        # Retirado
  rescheduled:   "bg-amber-500 text-white",        # Reprogramado
  return:        "bg-orange-600 text-white",       # Devolución
  cancelled:     "bg-red-600 text-white",          # Cancelado
  delivered:     "bg-green-500 text-white"         # Entregado
}.freeze


  # Clases CSS para tabs activos
TAB_ACTIVE_CLASSES = {
  pending_pickup: 'border-yellow-500 text-yellow-600',
  in_warehouse:  'border-blue-500 text-blue-600',
  in_transit:    'border-blue-600 text-blue-700',
  picked_up:     'border-green-600 text-green-700',
  rescheduled:   'border-amber-500 text-amber-600',
  return:        'border-orange-600 text-orange-700',
  cancelled:     'border-red-600 text-red-700',
  delivered:     'border-green-500 text-green-600'
}.freeze


  # Clases CSS para badges de tabs activos
TAB_BADGE_ACTIVE_CLASSES = {
  pending_pickup: 'bg-yellow-200 text-yellow-700',
  in_warehouse:  'bg-blue-200 text-blue-700',
  in_transit:    'bg-blue-300 text-blue-800',
  picked_up:     'bg-green-200 text-green-700',
  rescheduled:   'bg-amber-200 text-amber-700',
  return:        'bg-orange-200 text-orange-700',
  cancelled:     'bg-red-200 text-red-700',
  delivered:     'bg-green-200 text-green-700'
}.freeze


  # Returns CSS classes for status badge based on status
  def status_badge_classes(status)
    status_sym = normalize_status(status)
    STATUS_BADGE_CLASSES.fetch(status_sym, "bg-gray-100 text-gray-800")
  end
  alias_method :status_badge_class, :status_badge_classes

  # Returns human-readable status text in Spanish
  def status_text(status)
    status_sym = normalize_status(status)
    STATUS_TRANSLATIONS.fetch(status_sym, status.to_s.humanize)
  end

  # Returns options for select of statuses (translated)
  def status_select_options
    STATUS_TRANSLATIONS.map { |key, value| [value, key.to_s] }
  end

  # Returns status translations as JSON for JavaScript
  def status_translations_json
    STATUS_TRANSLATIONS.to_json
  end

  # Returns classes for filter tab
  def tab_classes(current_status, tab_status)
    if current_status == tab_status
      status_sym = normalize_status(tab_status)
      TAB_ACTIVE_CLASSES.fetch(status_sym, 'border-indigo-500 text-indigo-600')
    else
      'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
    end
  end

  # Returns classes for tab badge
  def tab_badge_classes(current_status, tab_status)
    if current_status == tab_status
      status_sym = normalize_status(tab_status)
      TAB_BADGE_ACTIVE_CLASSES.fetch(status_sym, 'bg-indigo-100 text-indigo-600')
    else
      'bg-gray-100 text-gray-900'
    end
  end

  # === HELPERS PARA FILTROS ===

  # Returns grouped commune options for select (grouped by region)
  # Receives pre-loaded communes to avoid duplicate queries
  def commune_select_options(communes)
    communes.group_by(&:region)
            .map { |region, region_communes| [region.name, region_communes.map { |c| [c.name, c.id] }] }
  end

  # Returns driver options for select with name and vehicle plate
  # Receives pre-loaded drivers to avoid duplicate queries
  def driver_select_options(drivers)
    drivers.map do |driver|
      label = driver.name.present? ? "#{driver.name} - #{driver.vehicle_plate}" : "#{driver.email} - #{driver.vehicle_plate}"
      [label, driver.id]
    end
  end

  # Returns communes as JSON for autocomplete (simple array of {id, name})
  def communes_json(communes)
    communes.map { |c| { id: c.id, name: c.name } }.to_json
  end

  # Returns drivers as JSON for autocomplete (simple array of {id, name})
  def drivers_json(drivers)
    drivers.map do |d|
      label = d.name.present? ? "#{d.name} - #{d.vehicle_plate}" : "#{d.email} - #{d.vehicle_plate}"
      { id: d.id, name: label }
    end.to_json
  end

  # Returns text showing filtered results count
  def filtered_results_text(filtered_count, total_count)
    if filtered_count == total_count
      "Mostrando #{pluralize(filtered_count, 'paquete')}"
    else
      "Mostrando #{filtered_count} de #{pluralize(total_count, 'paquete')} (filtrado)"
    end
  end

  # Returns badge with filters count
  def filters_count_badge(count)
    return '' if count.zero?
    content_tag :span, count,
                class: "ml-2 inline-flex items-center justify-center px-2 py-1 text-xs font-bold leading-none text-white bg-indigo-600 rounded-full"
  end

  # Construye parámetros de filtro preservando los existentes y cambiando solo el status
  # Uso: filter_params_with_status('pending_pickup')
  def filter_params_with_status(new_status)
    {
      status: new_status,
      date_from: params[:date_from],
      date_to: params[:date_to],
      tracking_query: params[:tracking_query],
      commune_ids: params[:commune_ids],
      courier_ids: params[:courier_ids]
    }.compact # Elimina valores nil
  end

  private

  # Normaliza el estado a symbol
  def normalize_status(status)
    status.is_a?(String) ? status.to_sym : status
  end
end
