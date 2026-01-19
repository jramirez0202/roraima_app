# Sistema de Estados de Paquetes

**Última actualización:** Diciembre 2025

Este documento describe el sistema de estados (state machine) que controla el ciclo de vida de los paquetes en Roraima Delivery.

## Estados Disponibles

El sistema maneja 8 estados posibles para cada paquete:

```ruby
enum status: {
  pending_pickup: 0,   # Pendiente de retiro
  in_warehouse: 1,     # En bodega
  in_transit: 2,       # En camino (requiere courier asignado)
  rescheduled: 3,      # Reprogramado (tras intento fallido)
  delivered: 4,        # Entregado (TERMINAL)
  picked_up: 5,        # Retirado en punto (TERMINAL)
  return: 6,           # En devolución
  cancelled: 7         # Cancelado (TERMINAL)
}
```

### Clasificación de Estados

**Estados Iniciales:**
- `pending_pickup` - Estado por defecto al crear un paquete

**Estados de Tránsito:**
- `in_warehouse` - Paquete en bodega esperando asignación
- `in_transit` - Paquete asignado a conductor, en ruta
- `rescheduled` - Intento de entrega fallido, pendiente reprogramación
- `return` - Paquete en devolución al remitente

**Estados Terminales** (no permiten transiciones salvo admin_override):
- `delivered` - Entregado exitosamente
- `picked_up` - Retirado en punto de entrega
- `cancelled` - Cancelado

## Traducciones (Español)

| Estado (DB) | Español | Badge Class |
|-------------|---------|-------------|
| `pending_pickup` | Pendiente Retiro | `bg-yellow-100 text-yellow-800` |
| `in_warehouse` | Bodega | `bg-blue-100 text-blue-800` |
| `in_transit` | En Camino | `bg-indigo-100 text-indigo-800` |
| `rescheduled` | Reprogramado | `bg-orange-100 text-orange-800` |
| `delivered` | Entregado | `bg-green-100 text-green-800` |
| `picked_up` | Retirado | `bg-green-100 text-green-800` |
| `return` | Devolución | `bg-purple-100 text-purple-800` |
| `cancelled` | Cancelado | `bg-red-100 text-red-800` |

**Uso en vistas:**

```erb
<%= status_text(package.status) %>
<span class="<%= status_badge_classes(package.status) %>">
  <%= status_text(package.status) %>
</span>
```

## Transiciones Permitidas

```ruby
ALLOWED_TRANSITIONS = {
  pending_pickup: [:in_warehouse, :cancelled, :picked_up],
  in_warehouse: [:in_transit, :picked_up, :return, :cancelled],
  in_transit: [:delivered, :rescheduled, :return],
  rescheduled: [:in_transit, :return],
  delivered: [],  # TERMINAL
  picked_up: [],  # TERMINAL
  return: [:in_warehouse, :cancelled],
  cancelled: []   # TERMINAL
}.freeze
```

### Diagrama de Flujo

```
pending_pickup
  ├─> in_warehouse
  │     ├─> in_transit
  │     │     ├─> delivered ⊗ (TERMINAL)
  │     │     ├─> rescheduled
  │     │     │     └─> in_transit (bucle)
  │     │     └─> return
  │     │           ├─> in_warehouse (bucle)
  │     │           └─> cancelled ⊗ (TERMINAL)
  │     ├─> picked_up ⊗ (TERMINAL)
  │     ├─> return
  │     └─> cancelled ⊗ (TERMINAL)
  ├─> picked_up ⊗ (TERMINAL)
  └─> cancelled ⊗ (TERMINAL)

⊗ = Estado terminal (solo transiciones con admin_override)
```

## PackageStatusService

Toda la lógica de cambio de estado está centralizada en `PackageStatusService`:

```ruby
service = PackageStatusService.new

# Cambiar estado general
service.change_status(package, :in_transit, current_user, reason: "Asignado a conductor")

# Asignar courier (automáticamente cambia a in_transit)
service.assign_courier(package, driver, current_user)

# Marcar como entregado
service.mark_as_delivered(package, current_user, proof: "Firmado por cliente")

# Marcar como devolución
service.mark_as_devolucion(package, current_user, reason: "Dirección incorrecta")

# Registrar intento fallido (cambia a rescheduled)
service.register_failed_attempt(package, current_user, reason: "Cliente ausente")

# Reprogramar entrega (de rescheduled a in_transit)
service.reprogram(package, current_user, new_date: Date.tomorrow)
```

### Métodos Principales

#### change_status

```ruby
def change_status(package, new_status, user, options = {})
  # Opciones:
  # - reason: String (razón del cambio)
  # - location: String (ubicación GPS, opcional)
  # - admin_override: Boolean (forzar transición inválida)

  # Validaciones:
  # 1. Transición permitida
  # 2. Courier asignado si va a in_transit
  # 3. Admin override solo para admins

  # Registra en status_history (JSONB append-only)
  # Actualiza timestamps (delivered_at, cancelled_at, etc.)

  # Returns: true/false
  # Errors en: service.errors (Array)
end
```

**Ejemplo:**

```ruby
service = PackageStatusService.new
success = service.change_status(
  package,
  :delivered,
  current_user,
  reason: "Entregado a cliente",
  location: "-33.4489, -70.6693"
)

if success
  flash[:notice] = "Estado actualizado"
else
  flash[:alert] = service.errors.join(", ")
end
```

#### assign_courier

```ruby
def assign_courier(package, courier, user)
  # Validaciones:
  # 1. Courier es Driver (not admin/customer)
  # 2. Courier está activo
  # 3. Solo admins pueden asignar

  # Actualiza:
  # - assigned_courier_id
  # - assigned_at
  # - assigned_by_id
  # - status → in_transit

  # Returns: true/false
end
```

**Ejemplo:**

```ruby
driver = Driver.find(5)
service = PackageStatusService.new
success = service.assign_courier(package, driver, current_user)
```

#### mark_as_delivered

```ruby
def mark_as_delivered(package, user, options = {})
  # Opciones:
  # - proof: String (evidencia de entrega, opcional)
  # - location: String (GPS, opcional)

  # Validaciones:
  # 1. Paquete está in_transit
  # 2. User es admin o conductor asignado

  # Actualiza:
  # - status → delivered
  # - delivered_at → Time.current

  # Returns: true/false
end
```

**Ejemplo:**

```ruby
service = PackageStatusService.new
success = service.mark_as_delivered(
  package,
  current_driver,
  proof: "Firmado por Juan Pérez",
  location: "-33.4489, -70.6693"
)
```

#### register_failed_attempt

```ruby
def register_failed_attempt(package, user, options = {})
  # Opciones:
  # - reason: String (razón del fallo, requerido)

  # Actualiza:
  # - status → rescheduled
  # - Registra intento en status_history

  # Returns: true/false
end
```

**Ejemplo:**

```ruby
service = PackageStatusService.new
success = service.register_failed_attempt(
  package,
  current_driver,
  reason: "Cliente ausente, llamar para reprogramar"
)
```

## Historial de Estados (status_history)

Cada cambio de estado se registra en un array JSONB inmutable:

```ruby
package.status_history
# => [
#   {
#     "status" => "in_transit",
#     "previous_status" => "in_warehouse",
#     "timestamp" => "2025-12-26T10:30:00Z",
#     "user_id" => 5,
#     "reason" => "Asignado a conductor Juan",
#     "location" => "-33.4489, -70.6693",
#     "override" => false
#   },
#   {
#     "status" => "delivered",
#     "previous_status" => "in_transit",
#     "timestamp" => "2025-12-26T15:45:00Z",
#     "user_id" => 8,
#     "reason" => "Entregado a cliente",
#     "location" => "-33.4200, -70.6000",
#     "override" => false
#   }
# ]
```

### Queries sobre Historial

```ruby
# Paquetes que pasaron por estado "rescheduled"
Package.where("status_history @> ?", [{status: "rescheduled"}].to_json)

# Paquetes entregados por usuario específico
Package.where("status_history @> ?", [{status: "delivered", user_id: 8}].to_json)

# Paquetes con admin override
Package.where("status_history @> ?", [{override: true}].to_json)
```

## Admin Override

Los estados terminales normalmente no permiten transiciones, pero admins pueden forzarlas:

```ruby
# Sin override (falla si package.delivered?)
service.change_status(package, :in_transit, admin)
# => false, errors: ["Transición no permitida: delivered → in_transit"]

# Con override (funciona)
service.change_status(
  package,
  :in_transit,
  admin,
  admin_override: true,
  reason: "Reabrir por error en entrega"
)
# => true

# Se registra en historial con override: true
```

**IMPORTANTE:** Solo admins pueden usar `admin_override: true`. Si un customer o driver lo intenta, se rechaza.

## Timestamps Automáticos

Ciertos estados actualizan timestamps automáticamente:

| Estado | Timestamp Actualizado |
|--------|----------------------|
| `pending_pickup` → `in_warehouse` | `picked_at` |
| `in_warehouse` → `in_transit` | `shipped_at` |
| `in_transit` → `delivered` | `delivered_at` |
| `* → `cancelled` | `cancelled_at` |

**Implementación:**

```ruby
# PackageStatusService#change_status
case new_status.to_sym
when :delivered
  package.delivered_at = Time.current
when :in_transit
  package.shipped_at = Time.current if package.in_warehouse?
when :cancelled
  package.cancelled_at = Time.current
when :in_warehouse
  package.picked_at = Time.current if package.pending_pickup?
end
```

## Autorizaciones (Pundit)

Las políticas definen quién puede cambiar estados:

```ruby
# PackagePolicy
def change_status?
  user.admin? || (record.assigned_courier == user)
end

def mark_as_delivered?
  return false unless record.in_transit?
  user.admin? || record.assigned_courier == user
end

def assign_courier?
  user.admin?
end
```

**En el controlador:**

```ruby
class Admin::PackagesController < Admin::BaseController
  def change_status
    authorize @package, :change_status?

    service = PackageStatusService.new
    if service.change_status(@package, params[:status], current_user, params[:reason])
      redirect_to admin_package_path(@package), notice: "Estado actualizado"
    else
      redirect_to admin_package_path(@package), alert: service.errors.join(", ")
    end
  end
end
```

## Casos de Uso Comunes

### 1. Flujo Normal de Entrega

```ruby
# 1. Paquete creado
package = Package.create!(status: :pending_pickup, ...)

# 2. Retiran de remitente, llega a bodega
service.change_status(package, :in_warehouse, admin)

# 3. Admin asigna conductor
service.assign_courier(package, driver, admin)
# Status automáticamente cambia a in_transit

# 4. Conductor entrega
service.mark_as_delivered(package, driver, proof: "Firmado")
# Status: delivered, delivered_at: Time.current
```

### 2. Intento Fallido y Reprogramación

```ruby
# 1. Paquete en tránsito
package.in_transit? # => true

# 2. Conductor intenta entregar, cliente ausente
service.register_failed_attempt(package, driver, reason: "Cliente ausente")
# Status: rescheduled

# 3. Conductor reprograma para mañana
service.reprogram(package, driver, new_date: Date.tomorrow)
# Status: in_transit (nuevamente)

# 4. Segundo intento exitoso
service.mark_as_delivered(package, driver)
# Status: delivered
```

### 3. Devolución

```ruby
# 1. Paquete en tránsito
package.in_transit? # => true

# 2. Dirección incorrecta, marcar como devolución
service.mark_as_devolucion(package, driver, reason: "Dirección inexistente")
# Status: return

# 3. Llega a bodega
service.change_status(package, :in_warehouse, admin)

# 4. Se cancela (no se puede entregar)
service.change_status(package, :cancelled, admin, reason: "Dirección inválida confirmada")
# Status: cancelled
```

### 4. Admin Corrige Error

```ruby
# 1. Paquete marcado como entregado por error
package.delivered? # => true

# 2. Admin detecta error, reabre
service.change_status(
  package,
  :in_transit,
  admin,
  admin_override: true,
  reason: "Marcado entregado por error, reabrir"
)
# Status: in_transit

# 3. Conductor entrega correctamente
service.mark_as_delivered(package, driver)
```

## Dashboard y Contadores

Los estados se usan para dashboards y KPIs:

```ruby
# Dashboard de Admin
Package.pending_pickup.count  # Paquetes esperando retiro
Package.in_warehouse.count    # Paquetes en bodega
Package.in_transit.count      # Paquetes en ruta
Package.rescheduled.count     # Reprogramados
Package.delivered.count       # Entregados hoy
Package.return.count          # Devoluciones

# Dashboard de Driver
driver.assigned_packages.in_transit.count
driver.assigned_packages.rescheduled.count
driver.assigned_packages.delivered.count
```

**Vista de Dashboard:**

```erb
<div class="stats">
  <div class="stat">
    <span class="label">En Camino</span>
    <span class="count"><%= @in_transit_count %></span>
  </div>
  <div class="stat">
    <span class="label">Reprogramados</span>
    <span class="count"><%= @rescheduled_count %></span>
  </div>
  <div class="stat">
    <span class="label">Entregados Hoy</span>
    <span class="count"><%= @delivered_today_count %></span>
  </div>
</div>
```

## Testing de Estados

```ruby
# test/services/package_status_service_test.rb
test "cambia estado correctamente" do
  package = create(:package, status: :in_warehouse)
  admin = create(:user, :admin)
  service = PackageStatusService.new

  assert service.change_status(package, :in_transit, admin)
  assert package.reload.in_transit?
end

test "rechaza transición inválida" do
  package = create(:package, status: :delivered)
  admin = create(:user, :admin)
  service = PackageStatusService.new

  refute service.change_status(package, :in_transit, admin)
  assert_includes service.errors, "Transición no permitida"
end

test "admin puede forzar con override" do
  package = create(:package, status: :delivered)
  admin = create(:user, :admin)
  service = PackageStatusService.new

  assert service.change_status(
    package,
    :in_transit,
    admin,
    admin_override: true
  )
  assert package.reload.in_transit?
end
```

## Referencias

- [Arquitectura - Decisiones](../architecture/decisions.md#adr-003-historial-de-estados-en-jsonb)
- [CLAUDE.md](../../CLAUDE.md) - Sección "Package State Machine"
- Código fuente:
  - `app/models/package.rb` (ALLOWED_TRANSITIONS)
  - `app/services/package_status_service.rb`
  - `app/helpers/packages_helper.rb` (STATUS_TRANSLATIONS)
