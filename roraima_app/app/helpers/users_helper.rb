module UsersHelper
  # Retorna las clases CSS para el badge de role
  def role_badge_classes(role)
    case role.to_sym
    when :admin
      "bg-red-100 text-red-800"
    when :customer
      "bg-blue-100 text-blue-800"
    when :driver
      "bg-green-100 text-green-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end

  # Retorna el texto del role en español
  def role_text(role)
    case role.to_sym
    when :admin
      "Administrador"
    when :customer
      "Cliente"
    when :driver
      "Conductor"
    else
      role.to_s.humanize
    end
  end

  # Retorna las clases CSS para el badge de estado activo/inactivo
  def status_badge_classes(active)
    active ? "bg-green-100 text-green-800" : "bg-red-100 text-red-800"
  end

  # Retorna el texto del estado
  def status_text(active)
    active ? "Activo" : "Inactivo"
  end

  # Formatea el RUT para display (sin el formato original si está vacío)
  def format_rut(rut)
    return "—" if rut.blank?
    rut
  end
end
