module PackagesHelper
  # Traducciones centralizadas de estados
  STATUS_TRANSLATIONS = {
    pending_pickup: "Pendiente Retiro",
    in_warehouse: "Bodega",
    in_transit: "En Camino",
    rescheduled: "Reprogramado",
    delivered: "Entregado",
    return: "Devolución",
    cancelled: "Cancelado"
  }.freeze

  # Clases CSS para badges de estado (Usa clases centralizadas de colors.css)
STATUS_BADGE_CLASSES = {
  pending_pickup: "badge-pending",       # Pendiente → usa var(--color-status-pending-bg/text)
  in_warehouse:  "badge-warehouse",      # Bodega → usa var(--color-status-warehouse-bg/text)
  in_transit:    "badge-transit",        # En camino → usa var(--color-status-transit-bg/text)
  rescheduled:   "badge-rescheduled",    # Reprogramado → usa var(--color-status-rescheduled-bg/text)
  return:        "badge-return",         # Devolución → usa var(--color-status-return-bg/text)
  cancelled:     "badge-cancelled",      # Cancelado → usa var(--color-status-cancelled-bg/text)
  delivered:     "badge-delivered"       # Entregado → usa var(--color-status-delivered-bg/text)
}.freeze


  # Clases CSS para tabs activos
TAB_ACTIVE_CLASSES = {
  pending_pickup: 'border-yellow-500 text-yellow-600',
  in_warehouse:  'border-blue-500 text-blue-600',
  in_transit:    'border-blue-600 text-blue-700',
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

  # Returns customer-visible status text with visibility logic
  # If status is hidden, returns generic "En proceso" text
  # @param package [Package] The package instance
  # @return [String] Translated status text (real or generic)
  def customer_visible_status_text(package)
    status = package.status.to_sym

    if Setting.status_visible_for_customers?(status)
      status_text(status)
    else
      "En proceso"
    end
  end

  # Returns options for select of statuses (translated)
  def status_select_options
    STATUS_TRANSLATIONS.map { |key, value| [value, key.to_s] }
  end

  # Returns options for select of statuses for drivers (only relevant statuses)
  def driver_status_select_options
    allowed_statuses = [:in_transit, :delivered, :rescheduled, :cancelled]
    STATUS_TRANSLATIONS.select { |key, _| allowed_statuses.include?(key) }
                       .map { |key, value| [value, key.to_s] }
  end

  # Returns status translations as JSON for JavaScript
  def status_translations_json
    STATUS_TRANSLATIONS.to_json
  end

  # === PROVIDER HELPERS ===

  # Provider row background colors (very light, subtle)
  PROVIDER_ROW_COLORS = {
    'PKG' => '',  # White (no class, default)
    'MLB' => 'bg-yellow-50',   # Very light yellow
    'FLB' => 'bg-green-50'     # Very light green
  }.freeze

  # Provider badge colors
  PROVIDER_BADGE_COLORS = {
    'PKG' => 'bg-gray-100 text-gray-800',
    'MLB' => 'bg-yellow-100 text-yellow-800',
    'FLB' => 'bg-green-100 text-green-800'
  }.freeze

  # Returns row background class for provider
  def provider_row_class(provider)
    PROVIDER_ROW_COLORS.fetch(provider, '')
  end

  # Returns badge classes for provider
  def provider_badge_class(provider)
    PROVIDER_BADGE_COLORS.fetch(provider, 'bg-gray-100 text-gray-800')
  end


  # Returns provider display name
  def provider_name(provider)
    Package::PROVIDER_NAMES[provider] || provider
  end

  # Returns provider badge HTML
  def provider_badge(package)
    content_tag :span,
      class: "inline-flex items-center px-2 py-0.5 rounded text-xs font-medium #{provider_badge_class(package.provider)}" do
      "#{provider_name(package.provider)}"
    end
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

  # Returns customers as JSON for autocomplete (simple array of {id, name})
  def customers_json(customers)
    customers.map do |c|
      label = "#{c.name} - #{c.email}"
      label += " (#{c.company})" if c.company.present?
      { id: c.id, name: label }
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

  # === PAYMENT METHOD TRANSLATIONS ===

  PAYMENT_METHOD_TRANSLATIONS = {
    cash: "Efectivo",
    transfer: "Transferencia"
  }.freeze

  # Returns human-readable payment method text in Spanish
  def payment_method_text(payment_method)
    payment_method_sym = payment_method.is_a?(String) ? payment_method.to_sym : payment_method
    PAYMENT_METHOD_TRANSLATIONS.fetch(payment_method_sym, payment_method.to_s.humanize)
  end

  # Returns payment method options for radio buttons
  def payment_method_options
    [
      { label: 'Efectivo', value: 'cash' },
      { label: 'Transferencia', value: 'transfer' }
    ]
  end

  # === STATUS OPTIONS FOR FORMS ===

  # Returns available status options for driver status change form
  # Each option includes label (Spanish), value (status key), and icon (emoji)
  def available_status_options
    [
      { label: 'Entregado', value: 'delivered', icon: '✅' },
      { label: 'En Camino', value: 'in_transit', icon: '🚚' },
      { label: 'Reprogramado', value: 'rescheduled', icon: '📅' },
      { label: 'Cancelado', value: 'cancelled', icon: '❌' }
    ]
  end

  # Returns status options excluding the package's current status
  # Used in forms to prevent selecting the same status
  def available_status_options_for(package)
    available_status_options.reject { |option| option[:value] == package.status }
  end

  # === DISPLAY HELPERS FOR MLB/FLB PACKAGES ===

  # Returns display value for customer_name, showing provider for MLB/FLB empty values
  def display_customer_name(package)
    return package.customer_name if package.customer_name.present? && package.customer_name != 'Por Asignar'

    # Si es MLB o FLB y el nombre está vacío/genérico, mostrar provider
    if %w[MLB FLB].include?(package.provider)
      package.provider_name
    else
      package.customer_name.presence || '—'
    end
  end

  # Returns display value for address, showing provider for MLB/FLB empty values
  def display_address(package)
    return package.address if package.address.present? && package.address != 'Por Asignar'

    # Si es MLB o FLB y la dirección está vacía/genérica, mostrar provider
    if %w[MLB FLB].include?(package.provider)
      package.provider_name
    else
      package.address.presence || '—'
    end
  end

  # Returns display text for unassigned driver in select, showing provider for MLB/FLB
  def display_unassigned_driver(package)
    if %w[MLB FLB].include?(package.provider)
      package.provider_name
    else
      'Sin asignar'
    end
  end

  # === CONDITIONAL DISPLAY HELPERS ===

  # Determines if receiver details section should be displayed
  # Shows when package is delivered and has receiver information
  def show_receiver_details?(package)
    package.delivered? && (package.receiver_name.present? || package.receiver_observations.present?)
  end

  # Determines if proof photos section should be displayed
  # Shows when package is delivered and has photos attached
  def show_proof_photos?(package)
    package.proof_photos.attached? && package.delivered?
  end

  # Determines if reschedule photos should be displayed
  # Shows when package has reschedule photos attached
  def show_reschedule_photos?(package)
    package.reschedule_photos.attached?
  end

  # Determines if reschedule info section should be displayed
  # Shows when package is rescheduled and has any reschedule data
  def show_reschedule_section?(package)
    (package.reprogramed_to || package.reprogram_motive || package.reschedule_photos.attached?) && package.rescheduled?
  end

  private

  # Normaliza el estado a symbol
  def normalize_status(status)
    status.is_a?(String) ? status.to_sym : status
  end
end
