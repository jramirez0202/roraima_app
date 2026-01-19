# Arquitectura del Sistema - Roraima Delivery

**Última actualización:** Diciembre 2025

## Visión General

Roraima Delivery es un sistema de gestión de paquetería y entregas construido con Ruby on Rails 7.1.5, diseñado específicamente para operaciones en Chile (16 regiones, 345+ comunas).

## Stack Tecnológico

### Backend
- **Framework:** Ruby on Rails 7.1.5 (Ruby 3.2.2)
- **Base de Datos:** PostgreSQL 12+ (Puerto 5433)
- **Jobs en Background:** Sidekiq 7.0
- **Autenticación:** Devise
- **Autorización:** Pundit
- **Paginación:** Pagy 6.0
- **Procesamiento de Archivos:** Roo (CSV/Excel)
- **Generación de PDFs:** Prawn + rqrcode

### Frontend
- **JavaScript:** Stimulus JS (interactividad)
- **Turbo:** Turbo Rails (navegación SPA-like)
- **Estilos:** Tailwind CSS
- **Módulos:** ImportMap (sin Node build step)

### Testing
- **Framework:** Minitest
- **Factories:** FactoryBot
- **E2E:** Capybara + Selenium

## Arquitectura de Usuarios (STI)

El sistema usa **Single Table Inheritance (STI)** para gestionar tres tipos de usuarios:

```
User (tabla base)
├── Admin (role: :admin, type: nil)
├── Customer (role: :customer, type: nil)
└── Driver (role: :driver, type: 'Driver') # STI subclass
```

### Campos del Modelo User

**Campos Comunes (todos los usuarios):**
- `email`, `password` (Devise)
- `name`, `company`, `phone`
- `role` (enum: admin:0, customer:1, driver:2)
- `active` (boolean)
- `company_logo` (ActiveStorage)

**Campos Específicos de Driver (STI):**
- `type` = 'Driver'
- `vehicle_plate`, `vehicle_model`, `vehicle_capacity`
- `assigned_zone_id` (FK a zones)

### API Unificada para Roles

```ruby
# ✅ SIEMPRE usar estos métodos
user.admin?
user.customer?
user.driver?

# ❌ NUNCA usar en vistas/controladores
user.is_a?(Driver)
```

## Arquitectura de Paquetes

### Modelo Package

Campos principales:
- **Identificación:** `tracking_code` (14 dígitos únicos)
- **Cliente:** `customer_name`, `phone`, `address`, `commune_id`
- **Estado:** `status` (enum con 8 estados)
- **Asignación:** `assigned_courier_id`, `assigned_at`, `assigned_by_id`
- **Timestamps:** `loading_date`, `picked_at`, `shipped_at`, `delivered_at`, `cancelled_at`
- **Financiero:** `amount` (monto a cobrar)
- **Opciones:** `exchange` (devolución), `order_number`
- **Auditoría:** `status_history` (JSONB), `bulk_upload_id`

### Máquina de Estados

```ruby
enum status: {
  pending_pickup: 0,  # Estado inicial
  in_warehouse: 1,    # En bodega
  in_transit: 2,      # En camino (requiere courier)
  rescheduled: 3,     # Reprogramado
  delivered: 4,       # Entregado (TERMINAL)
  picked_up: 5,       # Retirado (TERMINAL)
  return: 6,          # Devolución
  cancelled: 7        # Cancelado (TERMINAL)
}
```

**Transiciones Permitidas:**

```
pending_pickup → in_warehouse → in_transit → delivered
                              ↘ rescheduled → in_transit
                              ↘ return → in_warehouse
                                        ↘ cancelled
```

Los estados terminales (`delivered`, `picked_up`, `cancelled`) solo permiten transiciones con `admin_override: true`.

### Historial de Estados (JSONB)

Cada cambio de estado se registra en `status_history`:

```json
[
  {
    "status": "in_transit",
    "previous_status": "in_warehouse",
    "timestamp": "2025-12-26T10:30:00Z",
    "user_id": 5,
    "reason": "Asignado a conductor",
    "location": null,
    "override": false
  }
]
```

## Arquitectura de Zonas

### Modelo Zone

```ruby
class Zone < ApplicationRecord
  belongs_to :region
  has_many :drivers
  has_many :packages, through: :drivers

  # Comunas stored as JSONB array
  # communes: [1, 5, 12, 28]
end
```

Las zonas agrupan comunas para asignar drivers geográficamente.

## Capa de Servicios

La lógica de negocio está extraída en servicios:

### PackageStatusService
- `change_status(package, new_status, user, opts)`
- `assign_courier(package, courier, user)`
- `mark_as_delivered(package, user, proof)`
- `register_failed_attempt(package, user, reason)`

### BulkPackageUploadService
- Procesamiento masivo de CSV/XLSX
- Normalización de teléfonos (`+569XXXXXXXX`)
- Validación row-by-row
- Broadcast de progreso vía Turbo Streams

### LabelGeneratorService
- Generación de etiquetas PDF (A6)
- QR codes con datos del paquete
- Logo del cliente si está disponible

## Capa de Autorización (Pundit)

Todas las reglas de autorización están centralizadas en políticas:

### PackagePolicy

**Scopes:**
- Admin → todos los paquetes
- Customer → solo `user_id == current_user.id`
- Driver → solo `assigned_courier_id == current_user.id`

**Acciones:**
- `create?` → Admin o Customer (NO drivers)
- `update?` → Admin o owner
- `assign_courier?` → Solo Admin
- `change_status?` → Admin o driver asignado
- `mark_as_delivered?` → Admin o driver (si in_transit)

## Namespacing de Controladores

```
Admin::BaseController
├── before_action :require_admin!
└── Controllers: PackagesController, DriversController, ZonesController

Customers:: namespace
├── Scoped queries: policy_scope(current_user.packages)
└── Controllers: PackagesController, BulkUploadsController

Drivers:: namespace
├── before_action :require_driver!
└── Controllers: PackagesController, DashboardController
```

## Base de Datos

### Índices Críticos

```sql
-- Composite indexes
CREATE INDEX packages_on_user_id_and_status ON packages(user_id, status);
CREATE INDEX packages_on_status_and_assigned_courier_id ON packages(status, assigned_courier_id);
CREATE INDEX packages_on_assigned_courier_id_and_assigned_at ON packages(assigned_courier_id, assigned_at);

-- Trigram index para búsqueda rápida de tracking codes
CREATE INDEX packages_on_tracking_code_trigram ON packages USING GIN (tracking_code gin_trgm_ops);
```

### Búsqueda Trigram

El índice trigram permite búsquedas ultrarrápidas:

```ruby
# Buscar por primeros dígitos: "PKG-861"
# Buscar por últimos dígitos: "465"
# Buscar por cualquier parte: "2264"
Package.where("tracking_code ILIKE ?", "%#{query}%")  # O(log n) con GIN index
```

### JSONB Fields

- `packages.status_history` → Array de transiciones
- `bulk_uploads.error_details` → Array de errores por fila
- `zones.communes` → Array de IDs de comunas

## Configuración Especial

- **PostgreSQL:** Puerto **5433** (no estándar)
- **Devise:** Registro deshabilitado (admins crean usuarios)
- **Sidekiq:** Web UI en `/sidekiq` (solo admins)
- **Active Storage:** Logos, archivos de carga, PDFs generados
- **Tailwind:** Requiere `bin/dev` o `rails tailwindcss:watch`

## Patrones de Código

### Eager Loading (evitar N+1)

```ruby
# ✅ CORRECTO
packages = Package.includes(:region, :commune, :assigned_courier)

# ❌ INCORRECTO
packages = Package.all  # Causa N+1 queries
```

### Status Translations (centralizado)

Todas las traducciones de estados están en `PackagesHelper::STATUS_TRANSLATIONS`:

```ruby
# ✅ CORRECTO
status_text(package.status)  # Helper method

# ❌ OBSOLETO (evitar en código nuevo)
package.status_i18n  # Funciona pero está deprecated
```

## Diagrama de Relaciones

```
User (STI)
├── has_many :packages (como owner)
├── has_many :assigned_packages (como courier)
└── belongs_to :assigned_zone (si es Driver)

Package
├── belongs_to :user (owner)
├── belongs_to :assigned_courier (User)
├── belongs_to :commune
├── belongs_to :region
├── belongs_to :bulk_upload (opcional)
└── belongs_to :assigned_by (User)

Zone
├── belongs_to :region
├── has_many :drivers
└── has_many :communes (vía JSONB array)

BulkUpload
├── belongs_to :user
└── has_many :packages
```

## Referencias

- [Decisiones de Arquitectura](./decisions.md)
- [Diagrams](./diagrams.md)
- [CLAUDE.md](../../CLAUDE.md) - Guía completa para desarrollo
