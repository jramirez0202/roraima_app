# Diagramas de Arquitectura

**Última actualización:** Diciembre 2025

## Diagrama de Entidades y Relaciones (ERD)

```
┌─────────────────────────────────────────────────────────────────┐
│                    USERS (STI Base Table)                        │
├─────────────────────────────────────────────────────────────────┤
│ id                                                               │
│ email                                                            │
│ encrypted_password                                               │
│ name, company, phone                                             │
│ role (enum: admin:0, customer:1, driver:2)                      │
│ active (boolean)                                                 │
│ type (string) ─────┐  STI discriminator                         │
│                    │                                             │
│ # Driver-specific fields (NULL for Admin/Customer)              │
│ vehicle_plate      │                                             │
│ vehicle_model      │                                             │
│ vehicle_capacity   │                                             │
│ assigned_zone_id ──┼───────────────┐                            │
└────────────────────┼────────────────┼────────────────────────────┘
                     │                │
                     ▼                │
            ┌────────────────┐        │
            │ Driver         │        │
            │ (type='Driver')│        │
            └────────────────┘        │
                                      │
                     ┌────────────────▼────────────────┐
                     │          ZONES                  │
                     ├─────────────────────────────────┤
                     │ id                              │
                     │ name                            │
                     │ region_id ───────┐              │
                     │ communes (JSONB)  │              │
                     │   [1, 5, 12, 28]  │              │
                     │ active            │              │
                     └──────────┬────────┼──────────────┘
                                │        │
                                │        ▼
                                │   ┌─────────────┐
                                │   │  REGIONS    │
                                │   ├─────────────┤
                                │   │ id          │
                                │   │ name        │
                                │   └──────┬──────┘
                                │          │
                                │          │ has_many
                                │          ▼
                                │   ┌─────────────┐
                                └───│  COMMUNES   │
                                    ├─────────────┤
                                    │ id          │
                                    │ name        │
                                    │ region_id   │
                                    └──────▲──────┘
                                           │
                                           │ belongs_to
                                           │
┌──────────────────────────────────────────┼──────────────────────┐
│                      PACKAGES            │                      │
├──────────────────────────────────────────┼──────────────────────┤
│ id                                       │                      │
│ tracking_code (14 chars, unique, indexed)│                      │
│ customer_name, phone, address            │                      │
│ commune_id ──────────────────────────────┘                      │
│ region_id                                                        │
│                                                                  │
│ # Ownership & Assignment                                        │
│ user_id ────────────────────┐  owner (Customer/Admin)          │
│ assigned_courier_id ────────┼──┐  driver (User/Driver)         │
│ assigned_by_id ─────────────┼──┼──┐  who assigned              │
│ assigned_at                 │  │  │                             │
│                             │  │  │                             │
│ # State Machine             │  │  │                             │
│ status (enum)               │  │  │                             │
│ status_history (JSONB)      │  │  │                             │
│                             │  │  │                             │
│ # Timestamps                │  │  │                             │
│ loading_date                │  │  │                             │
│ picked_at                   │  │  │                             │
│ shipped_at                  │  │  │                             │
│ delivered_at                │  │  │                             │
│ cancelled_at                │  │  │                             │
│                             │  │  │                             │
│ # Financial & Options       │  │  │                             │
│ amount                      │  │  │                             │
│ exchange (boolean)          │  │  │                             │
│ order_number                │  │  │                             │
│                             │  │  │                             │
│ # Traceability              │  │  │                             │
│ bulk_upload_id ───────────┐ │  │  │                             │
└───────────────────────────┼─┼─┼──┼─┼───────────────────────────┘
                            │ │ │  │ │
                            │ └─┼──┼─┼─────────┐
                            │   └──┼─┘         │
                            │      └───────────┼────────┐
                            │                  │        │
                            ▼                  ▼        ▼
                  ┌──────────────────┐    ┌────────────────┐
                  │  BULK_UPLOADS    │    │     USERS      │
                  ├──────────────────┤    │  (see above)   │
                  │ id               │    └────────────────┘
                  │ user_id          │
                  │ filename         │
                  │ status           │
                  │ processed_count  │
                  │ error_count      │
                  │ error_details    │
                  │   (JSONB)        │
                  └──────────────────┘
```

## Flujo de Estados de Paquetes

```
                        ┌──────────────────┐
                        │ pending_pickup   │ ◄── Estado inicial
                        └────────┬─────────┘
                                 │
                   ┌─────────────┼─────────────┐
                   │             │             │
                   ▼             ▼             ▼
            ┌─────────────┐ ┌──────────┐ ┌──────────┐
            │  cancelled  │ │in_warehouse│ │picked_up │
            └─────────────┘ └─────┬────┘ └──────────┘
                   ▲              │              ▲
                   │              │              │
                   │    ┌─────────┼──────────────┼────┐
                   │    │         │              │    │
                   │    │         ▼              │    │
                   │    │   ┌──────────┐         │    │
                   │    │   │in_transit│         │    │
                   │    │   └────┬─────┘         │    │
                   │    │        │               │    │
                   │    │   ┌────┼────┐          │    │
                   │    │   │    │    │          │    │
                   │    │   ▼    ▼    ▼          │    │
                   │    │ ┌────┐ ┌──────────┐ ┌──────┐
                   │    │ │delivered│ │rescheduled│ │return│
                   │    │ └────┘ └────┬─────┘ └───┬──┘
                   │    │             │           │
                   │    │             └───────────┼─────┐
                   │    │                         │     │
                   │    └─────────────────────────┘     │
                   │                                    │
                   └────────────────────────────────────┘

LEYENDA:
  ◄── Flujo principal
  Estados TERMINALES: delivered, picked_up, cancelled
  Transiciones desde TERMINALES requieren admin_override: true
```

## Arquitectura de Controladores (Namespacing)

```
┌───────────────────────────────────────────────────────────────┐
│                     ApplicationController                      │
│  ├─ before_action :authenticate_user!                         │
│  └─ helper_method :current_user                               │
└───────────────────────┬───────────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
        ▼               ▼               ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────────┐
│Admin::Base   │ │Customers::   │ │Drivers::         │
│Controller    │ │Controllers   │ │Controllers       │
├──────────────┤ ├──────────────┤ ├──────────────────┤
│require_admin!│ │policy_scope  │ │require_driver!   │
└──────┬───────┘ └──────┬───────┘ └────────┬─────────┘
       │                │                  │
       │                │                  │
 ┌─────┴─────┐    ┌─────┴──────┐    ┌──────┴────────┐
 │Packages   │    │Packages    │    │Packages       │
 │Drivers    │    │BulkUploads │    │Dashboard      │
 │Zones      │    │Profiles    │    │Profiles       │
 │Users      │    │            │    │               │
 │Settings   │    │            │    │               │
 │BulkUploads│    │            │    │               │
 └───────────┘    └────────────┘    └───────────────┘

RUTAS:
  /admin/packages
  /admin/drivers
  /admin/zones

  /customers/packages
  /customers/bulk_uploads

  /drivers/packages
  /drivers/dashboard
```

## Arquitectura de Servicios

```
┌────────────────────────────────────────────────────────────┐
│                    Service Layer                           │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  PackageStatusService                                      │
│  ├─ change_status(package, new_status, user, opts)        │
│  ├─ assign_courier(package, courier, user)                │
│  ├─ mark_as_delivered(package, user, proof)               │
│  ├─ register_failed_attempt(package, user, reason)        │
│  └─ @errors Array                                         │
│                                                            │
│  BulkPackageUploadService                                  │
│  ├─ process! → Parse CSV/XLSX                             │
│  ├─ build_package_params(row) → Normalize data            │
│  ├─ normalize_phone(phone) → +569XXXXXXXX                 │
│  ├─ find_commune(name) → Commune lookup                   │
│  └─ broadcast_progress(current, total) → Turbo Stream     │
│                                                            │
│  BulkPackageValidatorService                               │
│  ├─ validate_row(row, index)                              │
│  └─ Returns: { valid: bool, errors: [...] }               │
│                                                            │
│  LabelGeneratorService                                     │
│  ├─ generate → Prawn PDF                                  │
│  ├─ add_package_label(package) → QR code + data           │
│  └─ render → PDF binary                                   │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

## Flujo de Carga Masiva

```
     Usuario (Admin/Customer)
            │
            │ 1. Sube CSV/XLSX
            ▼
     BulkUploadsController#create
            │
            │ 2. Crea BulkUpload record
            │    (status: pending)
            ▼
     BulkPackageUploadJob.perform_later
            │
            │ 3. Sidekiq procesa en background
            ▼
     BulkPackageUploadService#process!
            │
            ├─ Parse CSV/XLSX (Roo)
            │
            ├─ Validar cada fila
            │  └─ BulkPackageValidatorService
            │
            ├─ Normalizar datos
            │  ├─ Teléfono → +569XXXXXXXX
            │  ├─ Comuna → ID lookup
            │  └─ Fecha → Date object
            │
            ├─ Crear paquetes (batch)
            │  └─ Package.create!(params)
            │
            └─ Broadcast progreso (cada 5 filas)
               └─ Turbo::StreamsChannel
                    │
                    ▼
               Vista actualiza en tiempo real
                    │
                    ▼
     BulkUpload.update(status: completed)
            │
            │ 4. Usuario ve resumen
            ▼
     /admin/bulk_uploads/:id
     /customers/bulk_uploads/:id
```

## Stack de Autorización (Pundit)

```
      Request
         │
         ▼
   Controller
         │
         │ authorize @package
         │ policy_scope(Package)
         ▼
   PackagePolicy
         │
         ├─ Scope#resolve
         │  ├─ Admin → Package.all
         │  ├─ Customer → user.packages
         │  └─ Driver → assigned_packages
         │
         └─ Action Methods
            ├─ index? → true (todos)
            ├─ show? → admin OR owner OR assigned
            ├─ create? → admin OR customer
            ├─ update? → admin OR owner
            ├─ assign_courier? → admin only
            └─ change_status? → admin OR assigned driver
```

## Índices de Base de Datos (Performance)

```sql
-- Composite Indexes (queries comunes optimizadas)
packages(user_id, status)              ← Customer filtra sus paquetes por estado
packages(status, assigned_courier_id)   ← Admin/Driver filtra por estado + courier
packages(assigned_courier_id, assigned_at) ← Driver ve paquetes asignados por fecha

-- Trigram Index (búsqueda parcial ultrarrápida)
packages.tracking_code GIN(gin_trgm_ops)  ← ILIKE '%PKG-861%' usa este índice

-- STI Index
users.type                             ← Driver.all optimizado

-- JSONB Indexes
zones.communes GIN                     ← WHERE communes @> '[5]'

-- Foreign Keys (integridad)
packages.user_id
packages.assigned_courier_id
packages.commune_id
packages.region_id
packages.bulk_upload_id
```

## Integración Frontend/Backend

```
┌─────────────────────────────────────────────────────────┐
│                    Frontend Stack                        │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Stimulus Controllers (JavaScript)                       │
│  ├─ filters_panel_controller.js                         │
│  ├─ sidebar_controller.js                               │
│  ├─ phone_controller.js                                 │
│  └─ sidebar_menu_controller.js                          │
│                                                          │
│  Turbo (SPA-like navigation)                            │
│  ├─ turbo:load events                                   │
│  ├─ Turbo Streams (real-time updates)                   │
│  └─ Turbo Frames (partial updates)                      │
│                                                          │
│  Tailwind CSS (utility-first)                           │
│  └─ Custom color palette (Chile brand)                  │
│                                                          │
└───────────────────┬─────────────────────────────────────┘
                    │
                    │ HTTP Requests
                    ▼
┌─────────────────────────────────────────────────────────┐
│                    Backend Stack                         │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Rails Controllers                                       │
│  ├─ JSON responses                                       │
│  ├─ Turbo Stream responses                              │
│  └─ HTML responses                                       │
│                                                          │
│  Rails Views (ERB)                                       │
│  ├─ Partials (_form, _filters, etc.)                    │
│  ├─ Layouts (application, admin, etc.)                  │
│  └─ data-controller attributes (Stimulus hooks)          │
│                                                          │
│  Rails Helpers                                           │
│  ├─ PackagesHelper (status_text, badge_classes)         │
│  └─ ApplicationHelper                                    │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## Referencias

- [Architecture Overview](./overview.md)
- [Architecture Decisions](./decisions.md)
- [CLAUDE.md](../../CLAUDE.md)
