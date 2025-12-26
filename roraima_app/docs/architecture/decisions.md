# Decisiones de Arquitectura (ADR)

**Última actualización:** Diciembre 2025

Este documento registra las decisiones arquitectónicas importantes tomadas en el proyecto Roraima Delivery.

---

## ADR-001: Single Table Inheritance (STI) para Drivers

**Fecha:** Noviembre 2025
**Estado:** ✅ Aceptado e Implementado

### Contexto

Necesitábamos diferenciar entre usuarios normales (Admin/Customer) y drivers (conductores), donde drivers tienen campos adicionales como vehículo, capacidad y zona asignada.

### Opciones Consideradas

1. **Roles con campos opcionales** - Agregar campos de vehículo a todos los users
2. **Tablas separadas** - `users` y `drivers` con relación 1:1
3. **STI (Single Table Inheritance)** - Subclase `Driver` de `User`

### Decisión

Implementar STI con `Driver` como subclase de `User`.

### Justificación

**Ventajas:**
- ✅ Hereda toda la funcionalidad de Devise (autenticación)
- ✅ Simplifica queries (`User.all` incluye drivers)
- ✅ Polimorfismo natural (`user.driver?` funciona para todos)
- ✅ No requiere joins para operaciones comunes
- ✅ Rails maneja automáticamente la creación del tipo correcto

**Desventajas:**
- ⚠️ Campos de driver son NULL para admin/customer
- ⚠️ Esquema de tabla menos normalizado

### Implementación

```ruby
# Migración
add_column :users, :type, :string
add_column :users, :vehicle_plate, :string
add_column :users, :vehicle_model, :string
add_column :users, :vehicle_capacity, :integer
add_reference :users, :assigned_zone

# Modelo
class Driver < User
  validates :vehicle_plate, presence: true
  belongs_to :assigned_zone, class_name: 'Zone', optional: true
end
```

### Consecuencias

- API unificada: `user.driver?`, `user.admin?`, `user.customer?`
- Evitamos `is_a?(Driver)` en vistas/controladores
- Factory: `FactoryBot.create(:driver)` crea drivers correctamente

---

## ADR-002: JSONB para Comunas en Zonas

**Fecha:** Noviembre 2025
**Estado:** ✅ Aceptado e Implementado

### Contexto

Las zonas de reparto agrupan múltiples comunas. Necesitábamos decidir cómo almacenar esta relación many-to-many.

### Opciones Consideradas

1. **Tabla join clásica** - `zones_communes` con dos FKs
2. **has_and_belongs_to_many (HABTM)** - Rails genera tabla join
3. **JSONB array** - Almacenar IDs de comunas como `[1, 5, 12, 28]`

### Decisión

Usar JSONB array en columna `zones.communes`.

### Justificación

**Ventajas:**
- ✅ Sin tabla adicional
- ✅ PostgreSQL indexa JSONB eficientemente
- ✅ Queries simples: `WHERE communes @> '[5]'`
- ✅ Admin puede editar comunas fácilmente (checkboxes)
- ✅ Menos joins en queries frecuentes

**Desventajas:**
- ⚠️ No hay FK constraints (integridad referencial manual)
- ⚠️ Más difícil hacer queries complejas de comunas

### Implementación

```ruby
# Migración
add_column :zones, :communes, :jsonb, default: []
add_index :zones, :communes, using: :gin

# Modelo
class Zone < ApplicationRecord
  validate :communes_exist_in_region

  def communes_exist_in_region
    return if communes.blank?
    valid_ids = region.communes.pluck(:id)
    invalid = communes - valid_ids
    errors.add(:communes, "contiene IDs inválidos: #{invalid.join(', ')}") if invalid.any?
  end
end
```

### Consecuencias

- Admin puede seleccionar comunas con checkboxes multi-select
- Query de paquetes por zona: `Package.joins(:commune).where("zones.communes @> ARRAY[communes.id]::jsonb")`
- Validación personalizada para integridad

---

## ADR-003: Historial de Estados en JSONB

**Fecha:** Noviembre 2025
**Estado:** ✅ Aceptado e Implementado

### Contexto

Necesitamos auditar todos los cambios de estado de paquetes con metadata (quién, cuándo, razón, override).

### Opciones Consideradas

1. **Tabla `package_status_transitions`** - Modelo separado
2. **Gem Audited/PaperTrail** - Versionado completo
3. **JSONB append-only array** - Array inmutable en `packages.status_history`

### Decisión

Usar JSONB array append-only en `packages.status_history`.

### Justificación

**Ventajas:**
- ✅ Historial siempre con el paquete (un solo query)
- ✅ Inmutable (solo append, nunca delete)
- ✅ Queries complejas posibles con JSONB operators
- ✅ Sin tabla adicional

**Desventajas:**
- ⚠️ Difícil reportar sobre transiciones globales
- ⚠️ Array puede crecer mucho (raro en la práctica)

### Implementación

```ruby
# Estructura del array
[
  {
    "status": "in_transit",
    "previous_status": "in_warehouse",
    "timestamp": "2025-12-26T10:30:00Z",
    "user_id": 5,
    "reason": "Asignado a conductor Juan",
    "location": null,
    "override": false
  }
]

# Append en PackageStatusService
new_entry = {
  status: new_status,
  previous_status: package.status,
  timestamp: Time.current,
  user_id: user.id,
  reason: reason,
  location: location,
  override: admin_override
}
package.status_history ||= []
package.status_history << new_entry
```

### Consecuencias

- Query: `Package.where("status_history @> ?", [{status: "delivered"}].to_json)`
- Nunca se pierden transiciones pasadas
- Admin puede ver timeline completo de cada paquete

---

## ADR-004: Traducción de Estados Centralizada

**Fecha:** Diciembre 2025
**Estado:** ✅ Aceptado e Implementado

### Contexto

Los estados de paquetes están en inglés en la DB (`pending_pickup`, `in_transit`) pero deben mostrarse en español en la UI.

### Opciones Consideradas

1. **I18n YAML files** - Rails estándar
2. **Case statements en el modelo** - Método `status_i18n`
3. **Hash constante en helper** - Single source of truth

### Decisión

Hash constante `STATUS_TRANSLATIONS` en `PackagesHelper`.

### Justificación

**Ventajas:**
- ✅ Single source of truth
- ✅ O(1) lookup vs O(n) case statements
- ✅ Fácil exportar a JavaScript con `status_translations_json`
- ✅ No requiere archivos YAML adicionales
- ✅ Cambios se propagan automáticamente

**Desventajas:**
- ⚠️ No soporta múltiples idiomas (no es requisito)

### Implementación

```ruby
# app/helpers/packages_helper.rb
STATUS_TRANSLATIONS = {
  pending_pickup: "Pendiente Retiro",
  in_warehouse: "Bodega",
  in_transit: "En Camino",
  delivered: "Entregado",
  # ...
}.freeze

def status_text(status)
  STATUS_TRANSLATIONS[status.to_sym] || status.to_s.titleize
end

# Uso en vistas
<%= status_text(package.status) %>
```

### Consecuencias

- Un solo lugar para actualizar traducciones
- JavaScript frontend tiene acceso a traducciones
- Model delega: `package.status_i18n` → `ApplicationController.helpers.status_text(status)`

---

## ADR-005: Índice Trigram para Tracking Codes

**Fecha:** Diciembre 2025
**Estado:** ✅ Aceptado e Implementado

### Contexto

Los usuarios buscan paquetes por partes del tracking code: primeros dígitos, últimos dígitos, o fragmentos intermedios. Un índice B-tree no ayuda en búsquedas `ILIKE '%fragmento%'`.

### Opciones Consideradas

1. **Full table scan** - Lento con miles de paquetes
2. **Elasticsearch/Solr** - Overkill para este caso
3. **PostgreSQL pg_trgm extension** - Índice GIN con trigrams

### Decisión

Usar `pg_trgm` extension con índice GIN.

### Justificación

**Ventajas:**
- ✅ Nativo de PostgreSQL (sin dependencias externas)
- ✅ Búsqueda O(log n) vs O(n)
- ✅ Funciona con `ILIKE '%query%'`
- ✅ Soporta búsqueda fuzzy

**Desventajas:**
- ⚠️ Índice más grande que B-tree
- ⚠️ Requiere extensión PostgreSQL

### Implementación

```ruby
# Migración
class AddTrigramIndexToPackagesTrackingCode < ActiveRecord::Migration[7.1]
  def up
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
    add_index :packages, :tracking_code, using: :gin, opclass: :gin_trgm_ops, name: 'index_packages_on_tracking_code_trigram'
  end

  def down
    remove_index :packages, name: 'index_packages_on_tracking_code_trigram'
  end
end

# Query
Package.where("tracking_code ILIKE ?", "%#{query}%")  # Usa el índice GIN
```

### Consecuencias

- Búsqueda de tracking codes es instantánea
- Usuarios pueden buscar "PKG-861", "465", "2264" y encuentra "PKG-86169301226465"
- Índice crece ~30% más que B-tree pero mejora performance 100x

---

## ADR-006: Sidekiq para Bulk Uploads

**Fecha:** Noviembre 2025
**Estado:** ✅ Aceptado e Implementado

### Contexto

Cargar 1000+ paquetes desde CSV bloqueaba la request HTTP por minutos.

### Opciones Consideradas

1. **Sincrónico** - Procesar en el request HTTP
2. **ActiveJob con Async adapter** - Sin persistencia de jobs
3. **Sidekiq** - Redis-backed background jobs

### Decisión

Usar Sidekiq con Redis.

### Justificación

**Ventajas:**
- ✅ No bloquea el request HTTP
- ✅ Web UI para monitorear jobs
- ✅ Retry automático en caso de fallos
- ✅ Persistencia de jobs en Redis
- ✅ Broadcasting de progreso con Turbo Streams

**Desventajas:**
- ⚠️ Requiere Redis en producción
- ⚠️ Complejidad adicional

### Implementación

```ruby
# app/jobs/bulk_package_upload_job.rb
class BulkPackageUploadJob < ApplicationJob
  queue_as :default

  def perform(bulk_upload_id)
    bulk_upload = BulkUpload.find(bulk_upload_id)
    service = BulkPackageUploadService.new(bulk_upload)
    service.process!
  end
end

# Controller
BulkPackageUploadJob.perform_later(@bulk_upload.id)
```

### Consecuencias

- Cargas masivas no bloquean la UI
- Admin puede monitorear en `/sidekiq`
- Jobs se reintentan automáticamente si fallan
- Broadcasting cada 5 filas con Turbo Streams

---

## ADR-007: Pundit para Autorización

**Fecha:** Noviembre 2025
**Estado:** ✅ Aceptado e Implementado

### Contexto

Necesitábamos reglas de autorización complejas: Admin ve todo, Customer solo sus paquetes, Driver solo asignados.

### Opciones Consideradas

1. **Checks manuales en controllers** - `if current_user.admin?`
2. **CanCanCan** - Autorización basada en abilities
3. **Pundit** - Autorización basada en políticas

### Decisión

Usar Pundit con políticas.

### Justificación

**Ventajas:**
- ✅ Políticas son POROs (Plain Old Ruby Objects)
- ✅ Fácil de testear
- ✅ Scopes centralizados (`policy_scope`)
- ✅ Errors automáticos (`authorize @package`)
- ✅ Filosofía Rails: Fat Model, Thin Controller

**Desventajas:**
- ⚠️ Más archivos (`app/policies/`)

### Implementación

```ruby
# app/policies/package_policy.rb
class PackagePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.driver?
        scope.where(assigned_courier: user)
      else
        scope.where(user: user)
      end
    end
  end

  def update?
    user.admin? || record.user == user
  end
end

# Controller
def index
  @packages = policy_scope(Package)
end

def update
  authorize @package
  # ...
end
```

### Consecuencias

- Lógica de autorización centralizada
- Tests de políticas independientes
- Scopes evitan leaks de información
- `Pundit::NotAuthorizedError` automático si no autorizado

---

## Resumen de Decisiones

| ADR | Decisión | Estado | Impacto |
|-----|----------|--------|---------|
| 001 | STI para Drivers | ✅ Activo | Alto - Afecta todo el sistema de usuarios |
| 002 | JSONB para Comunas | ✅ Activo | Medio - Simplifica gestión de zonas |
| 003 | JSONB para Historial | ✅ Activo | Alto - Auditoría completa |
| 004 | Traducciones Centralizadas | ✅ Activo | Bajo - Mejora mantenibilidad |
| 005 | Índice Trigram | ✅ Activo | Alto - Performance crítico |
| 006 | Sidekiq para Bulk | ✅ Activo | Alto - UX mejorada |
| 007 | Pundit | ✅ Activo | Alto - Seguridad centralizada |

## Referencias

- [Architecture Overview](./overview.md)
- [CLAUDE.md](../../CLAUDE.md)
