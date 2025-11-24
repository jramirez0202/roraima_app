module PackagesHelper
  # Devuelve las clases CSS para el badge de estado según el status
  def status_badge_classes(status)
    case status.to_sym
    when :pendiente_retiro
      "bg-yellow-100 text-yellow-800"
    when :en_bodega
      "bg-blue-100 text-blue-800"
    when :en_camino
      "bg-indigo-100 text-indigo-800"
    when :reprogramado
      "bg-orange-100 text-orange-800"
    when :entregado
      "bg-green-100 text-green-800"
    when :retirado
      "bg-teal-100 text-teal-800"
    when :devolucion
      "bg-red-100 text-red-800"
    when :cancelado
      "bg-gray-100 text-gray-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end

  # Devuelve el texto legible del estado
  def status_text(status)
    case status.to_sym
    when :pendiente_retiro
      "Pendiente Retiro"
    when :en_bodega
      "En Bodega"
    when :en_camino
      "En Camino"
    when :reprogramado
      "Reprogramado"
    when :entregado
      "Entregado"
    when :retirado
      "Retirado"
    when :devolucion
      "Devolución"
    when :cancelado
      "Cancelado"
    else
      status.to_s.humanize
    end
  end

  # Devuelve clases para el tab de filtro
  def tab_classes(current_status, tab_status)
    if current_status == tab_status
      case tab_status
      when 'pendiente_retiro'
        'border-yellow-500 text-yellow-600'
      when 'en_bodega'
        'border-blue-500 text-blue-600'
      when 'en_camino'
        'border-indigo-500 text-indigo-600'
      when 'reprogramado'
        'border-orange-500 text-orange-600'
      when 'entregado'
        'border-green-500 text-green-600'
      when 'retirado'
        'border-teal-500 text-teal-600'
      when 'devolucion'
        'border-red-500 text-red-600'
      when 'cancelado'
        'border-gray-500 text-gray-600'
      else
        'border-indigo-500 text-indigo-600'
      end
    else
      'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
    end
  end

  # Devuelve clases para el badge del tab
  def tab_badge_classes(current_status, tab_status)
    if current_status == tab_status
      case tab_status
      when 'pendiente_retiro'
        'bg-yellow-100 text-yellow-600'
      when 'en_bodega'
        'bg-blue-100 text-blue-600'
      when 'en_camino'
        'bg-indigo-100 text-indigo-600'
      when 'reprogramado'
        'bg-orange-100 text-orange-600'
      when 'entregado'
        'bg-green-100 text-green-600'
      when 'retirado'
        'bg-teal-100 text-teal-600'
      when 'devolucion'
        'bg-red-100 text-red-600'
      when 'cancelado'
        'bg-gray-100 text-gray-600'
      else
        'bg-indigo-100 text-indigo-600'
      end
    else
      'bg-gray-100 text-gray-900'
    end
  end
end
