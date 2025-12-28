# Glosario de Términos

**Última actualización:** Diciembre 2025

Este glosario define la terminología técnica y de negocio usada en Roraima Delivery.

---

## A

### Active Storage
Sistema de Rails para gestionar uploads de archivos. En Roraima se usa para logos de empresas, archivos CSV de carga masiva y PDFs generados.

### ActiveRecord
ORM (Object-Relational Mapping) de Rails que mapea tablas de base de datos a clases Ruby. Ejemplos: `Package`, `User`, `Driver`.

### Admin
Rol de usuario con permisos completos del sistema. Puede crear users, asignar conductores, cambiar estados con override, ver Sidekiq UI.

### Admin Override
Flag que permite a admins forzar transiciones de estado normalmente no permitidas. Ejemplo: reabrir un paquete `delivered`.

### Allowed Transitions
Hash constante `ALLOWED_TRANSITIONS` en el modelo `Package` que define qué transiciones de estado son válidas.

### Assigned Courier
Conductor asignado a un paquete. Relación `belongs_to :assigned_courier, class_name: 'User'`.

---

## B

### Badge Classes
Clases CSS de Tailwind para mostrar estados con colores. Definidas en `PackagesHelper::STATUS_BADGE_CLASSES`.

### Before Validation
Callback de ActiveRecord que se ejecuta antes de validar un modelo. Ejemplo: `before_validation :generate_tracking_code`.

### Bulk Upload
Proceso de crear múltiples paquetes desde un archivo CSV o XLSX. Ejecutado en background por Sidekiq.

### BulkPackageUploadService
Servicio que procesa archivos CSV/XLSX y crea paquetes en masa con normalización y validación.

### BulkPackageValidatorService
Servicio que valida filas de CSV antes de procesarlas, sin crear paquetes.

### BulkUpload (Modelo)
Modelo ActiveRecord que registra cada carga masiva: archivo, estado, contadores de éxito/error, detalles de errores.

---

## C

### Cancelled
Estado terminal de un paquete que fue cancelado. No permite transiciones (excepto con admin_override).

### CLAUDE.md
Archivo de documentación específico para Claude Code, contiene guías completas de desarrollo, patrones, comandos y arquitectura.

### Commune
Comuna (división administrativa) dentro de una región. Ejemplo: Providencia, Las Condes, Santiago.

### Customer
Rol de usuario que crea paquetes, hace cargas masivas y consulta su historial. No puede asignar conductores.

---

## D

### Delivered
Estado terminal de un paquete entregado exitosamente. Actualiza timestamp `delivered_at`.

### Devise
Gem de autenticación usada para login, logout y gestión de sesiones. El registro está deshabilitado (admins crean usuarios).

### Driver
Subclase STI de `User` con campos adicionales: `vehicle_plate`, `vehicle_model`, `vehicle_capacity`, `assigned_zone_id`.

### Driver Zone
Zona geográfica asignada a un conductor para optimizar rutas. Relación `belongs_to :assigned_zone`.

---

## E

### Eager Loading
Técnica para evitar N+1 queries cargando relaciones con `.includes()`. Ejemplo: `Package.includes(:commune)`.

### Enum
Tipo de dato Rails para campos con valores fijos. Ejemplo: `enum status: { pending_pickup: 0, in_warehouse: 1, ... }`.

### ERB (Embedded Ruby)
Motor de templates de Rails que mezcla HTML con código Ruby. Archivos `.html.erb`.

### Error Details
Campo JSONB en `BulkUpload` que almacena errores de validación por fila: `[{ row: 12, errors: [...], data: {...} }]`.

### Exchange
Campo booleano que indica si un paquete es devolución. En etiqueta PDF aparece como "DEVOLUCIÓN".

---

## F

### Factory (FactoryBot)
Patrón para crear objetos de test. Ejemplo: `FactoryBot.create(:package)` crea un paquete válido.

### Filterable Packages
Concern compartido entre controladores que implementa filtros de paquetes (estado, fecha, tracking).

---

## G

### GIN Index
Tipo de índice PostgreSQL usado para JSONB y arrays. Ejemplo: índice trigram en `tracking_code`.

### Gem
Biblioteca Ruby externa. Ejemplos: `devise`, `pundit`, `pagy`, `roo`, `prawn`.

---

## H

### HABTM (has_and_belongs_to_many)
Relación many-to-many en Rails con tabla join. No usada en Roraima (se usa JSONB para comunas).

### Helper
Métodos compartidos disponibles en vistas. Ejemplo: `PackagesHelper#status_text(status)`.

---

## I

### In Transit
Estado de paquete en camino con conductor asignado. Requiere `assigned_courier_id` no nulo.

### In Warehouse
Estado de paquete en bodega esperando asignación a conductor.

### ImportMap
Sistema de módulos JavaScript de Rails sin build step. Alternativa a Webpack/esbuild.

---

## J

### Job (Sidekiq)
Tarea ejecutada en background. Ejemplo: `BulkPackageUploadJob` procesa CSV sin bloquear request HTTP.

### JSONB
Tipo de dato PostgreSQL para almacenar JSON binario con índices. Usado en `status_history`, `error_details`, `communes`.

---

## K

### KPI (Key Performance Indicator)
Métrica clave. Ejemplos: paquetes entregados hoy, tasa de éxito de entregas, total recaudado.

---

## L

### Label Generator Service
Servicio que genera PDFs de etiquetas A6 con QR codes, datos de paquete y logo del cliente.

### Loading Date
Fecha en que el paquete fue cargado al sistema. Auto-asignada a `Date.current` en carga masiva.

### Locale
Configuración de idioma/región. Roraima usa español de Chile (`es-CL`).

---

## M

### Migration
Archivo Ruby que modifica el esquema de la base de datos. Ejemplo: `20251125_create_packages.rb`.

### Minitest
Framework de testing de Rails. Usado en vez de RSpec.

---

## N

### N+1 Query
Anti-patrón donde se ejecuta 1 query inicial + N queries en un loop. Solución: eager loading con `.includes()`.

### Namespace
Agrupación de clases/módulos. Ejemplos: `Admin::`, `Customers::`, `Drivers::`.

### Normalization
Proceso de estandarizar datos. Ejemplos: normalizar teléfono a `+569XXXXXXXX`, commune aliases.

---

## O

### ORM (Object-Relational Mapping)
Mapeo de tablas DB a objetos. Rails usa ActiveRecord.

### Override
Ver "Admin Override".

---

## P

### Package
Modelo principal de la aplicación. Representa un paquete para entregar.

### Package Status Service
Servicio que encapsula toda la lógica de cambio de estados de paquetes.

### Pagy
Gem de paginación ligera. Usado en índices de paquetes con 10 items por página.

### Partial
Vista reutilizable. Archivos con prefijo `_`. Ejemplo: `_filters_panel.html.erb`.

### Pending Pickup
Estado inicial de un paquete esperando retiro del remitente.

### pg_trgm
Extensión PostgreSQL para búsquedas trigram. Permite búsquedas rápidas con `ILIKE '%query%'`.

### Picked Up
Estado terminal de paquete retirado por cliente en punto de entrega.

### Policy (Pundit)
Clase que define autorizaciones. Ejemplo: `PackagePolicy#create?` define quién puede crear paquetes.

### PORO (Plain Old Ruby Object)
Objeto Ruby simple sin herencia especial. Las políticas de Pundit son POROs.

### Prawn
Gem para generar PDFs programáticamente. Usado en `LabelGeneratorService`.

### Puma
Servidor de aplicación Rails. Reemplaza WEBrick en producción.

### Pundit
Gem de autorización basada en políticas. Define qué usuarios pueden hacer qué acciones.

---

## Q

### QR Code
Código bidimensional generado en etiquetas PDF con datos del paquete en JSON.

---

## R

### Rails
Framework web MVC en Ruby. Versión usada: 7.1.5.

### Region
Región administrativa de Chile. Ejemplo: Región Metropolitana. El sistema actualmente solo usa RM.

### Rescheduled
Estado de paquete con intento de entrega fallido que debe reprogramarse.

### Return
Estado de paquete en devolución al remitente.

### Roo
Gem para parsear archivos CSV y XLSX. Usado en `BulkPackageUploadService`.

### Route Close
Funcionalidad planificada (no implementada) para cerrar rutas de conductores al final del día.

---

## S

### Scope (ActiveRecord)
Query reutilizable. Ejemplo: `Package.delivered` es scope para `where(status: :delivered)`.

### Scope (Pundit)
Define qué registros puede ver un usuario. Ejemplo: customer solo ve `where(user: current_user)`.

### Seeds
Datos iniciales cargados con `rails db:seed`. Incluye regiones, comunas, usuarios de test.

### Sidekiq
Sistema de procesamiento de jobs en background usando Redis. Usado para carga masiva.

### Single Table Inheritance (STI)
Patrón donde múltiples modelos comparten una tabla con columna `type`. Ejemplo: `Driver` hereda de `User`.

### Status
Estado actual de un paquete. Enum con 8 valores posibles.

### Status Badge Classes
Hash de clases CSS por estado. Ejemplo: `delivered: "bg-green-100 text-green-800"`.

### Status History
Array JSONB inmutable que registra todos los cambios de estado de un paquete.

### Status Translations
Hash centralizado `PackagesHelper::STATUS_TRANSLATIONS` que mapea estados a español.

### Stimulus
Framework JavaScript minimalista para interactividad. Usado en vez de React/Vue.

### STI
Ver "Single Table Inheritance".

---

## T

### Tailwind CSS
Framework CSS utility-first. Usado en vez de Bootstrap.

### Terminal State
Estado de paquete que no permite transiciones (excepto admin_override). Ejemplos: delivered, cancelled, picked_up.

### Tracking Code
Código único de 14 dígitos para identificar paquetes. Formato: `PKG-XXXXXXXXXXXXXXXX`.

### Trigram Index
Índice GIN en PostgreSQL que divide strings en trigramas para búsqueda rápida parcial.

### Turbo
Parte de Hotwire que permite navegación SPA-like sin JavaScript pesado. Incluye Turbo Streams para updates en tiempo real.

---

## U

### User
Modelo base para todos los usuarios del sistema. Usa enum `role` y STI para drivers.

---

## V

### Validation
Regla de negocio que verifica datos antes de guardar. Ejemplo: `validates :phone, format: /\A\+569\d{8}\z/`.

### VPS (Virtual Private Server)
Servidor virtual para hosting. Alternativa a Heroku. Ejemplos: DigitalOcean, Linode.

---

## W

### Warehouse
Ver "In Warehouse".

### Worker (Sidekiq)
Proceso Sidekiq que ejecuta jobs. En Heroku es un dyno tipo `worker`.

---

## X

### XLSX
Formato binario de Microsoft Excel. Soportado en carga masiva vía gem Roo.

---

## Z

### Zone
Zona geográfica que agrupa comunas. Usada para asignar drivers geográficamente. Almacena comunas en JSONB array.

---

## Abreviaciones Comunes

| Abreviación | Significado |
|-------------|-------------|
| ADR | Architecture Decision Record |
| API | Application Programming Interface |
| CRUD | Create, Read, Update, Delete |
| CSV | Comma-Separated Values |
| DB | Database |
| ERB | Embedded Ruby |
| ERD | Entity-Relationship Diagram |
| FK | Foreign Key |
| GIN | Generalized Inverted Index |
| JSONB | JSON Binary (PostgreSQL) |
| KPI | Key Performance Indicator |
| MVC | Model-View-Controller |
| N+1 | N+1 Query Problem |
| ORM | Object-Relational Mapping |
| PDF | Portable Document Format |
| PORO | Plain Old Ruby Object |
| QR | Quick Response (code) |
| RAM | Random Access Memory |
| RM | Región Metropolitana |
| SQL | Structured Query Language |
| SSL | Secure Sockets Layer |
| STI | Single Table Inheritance |
| TLS | Transport Layer Security |
| UI | User Interface |
| URL | Uniform Resource Locator |
| UUID | Universally Unique Identifier |
| VPS | Virtual Private Server |

---

## Referencias

- [Índice de Documentación](./index.md)
- [Architecture Overview](./architecture/overview.md)
- [CLAUDE.md](../CLAUDE.md)

---

**Última actualización:** Diciembre 2025
