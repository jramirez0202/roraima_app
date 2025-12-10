# Roraima Delivery App

![Ruby Version](https://img.shields.io/badge/ruby-3.2.2-red.svg)
![Rails Version](https://img.shields.io/badge/rails-7.1.5-red.svg)
![PostgreSQL](https://img.shields.io/badge/postgresql-latest-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

> Sistema de gestión de paquetería diseñado para el mercado chileno con cobertura nacional completa.

[//]: # (Placeholder para banner/logo del proyecto)

---

## 📋 Tabla de Contenidos

- [Descripción del Proyecto](#-descripción-del-proyecto)
- [Quick Start](#-quick-start)
- [Requisitos Previos](#-requisitos-previos)
- [Instalación Detallada](#️-instalación-detallada)
- [Tecnologías Principales](#️-tecnologías-principales)
- [Variables de Entorno](#️-variables-de-entorno)
- [Base de Datos](#️-base-de-datos)
- [Credenciales de Acceso](#-credenciales-de-acceso-desarrollo)
- [Cómo Ejecutar en Local](#-cómo-ejecutar-en-local)
- [Cómo Correr Pruebas](#-cómo-correr-pruebas)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Características Principales](#-características-principales)
- [Carga Masiva y Trazabilidad](#-carga-masiva-y-trazabilidad)
- [Contribuir](#-contribuir)
- [Licencia](#-licencia)

---

## 🚀 Descripción del Proyecto

**Roraima Delivery App** es un sistema completo de gestión de paquetería desarrollado específicamente para el mercado chileno. La aplicación permite administrar y rastrear paquetes de entrega con una cobertura geográfica completa de las 16 regiones de Chile y sus 345+ comunas.

### ¿Por qué existe?

Este proyecto nace de la necesidad de contar con una solución robusta y escalable para gestionar operaciones de paquetería y entregas, proporcionando:

- **Gestión centralizada**: Control total de paquetes desde un panel administrativo
- **Portal de clientes**: Acceso autogestionado para que clientes creen y rastreen sus envíos
- **Cobertura nacional**: Base de datos completa de regiones y comunas de Chile
- **Trazabilidad**: Seguimiento del estado de cada paquete (activo/cancelado)
- **Escalabilidad**: Arquitectura lista para crecer según las necesidades del negocio

### Características Destacadas

✅ Sistema de roles (Admin/Cliente) con autorización granular
✅ CRUD completo de paquetes con validaciones robustas
✅ **Carga masiva de paquetes** desde CSV/XLSX con trazabilidad completa
✅ Gestión geográfica: 16 regiones y 345+ comunas de Chile
✅ Cancelación de paquetes con registro de razón
✅ Marcado de paquetes de devolucion
✅ Programación de fechas de retiro
✅ Búsqueda y filtrado optimizado con índices de rendimiento
✅ Paginación para manejo eficiente de grandes volúmenes
✅ Interfaz moderna con Tailwind CSS

---

## 🚀 Quick Start

Para desarrolladores experimentados que quieren empezar rápidamente:

```bash
# Clonar el repositorio
git clone <url-del-repositorio>
cd roraima_app

# Instalar dependencias
bundle install
yarn install

# Configurar la base de datos (crea, migra y siembra datos)
rails db:setup

# Iniciar el servidor de desarrollo (con Tailwind CSS watch)
bin/dev
```

Accede a **http://localhost:3000** e inicia sesión con:
- **Admin**: `admin@paqueteria.com` / `password123`
- **Cliente**: `customer1@example.com` / `password123`

---

## 📋 Requisitos Previos

Asegúrate de tener instalado lo siguiente antes de comenzar:

| Requisito | Versión Requerida | Notas |
|-----------|-------------------|-------|
| **Ruby** | 3.2.2 | Usa rbenv o rvm |
| **Rails** | 7.1.5+ | Se instala con bundle |
| **PostgreSQL** | 12+ | **Puerto 5433** (no estándar) |
| **Node.js** | 18+ | Para asset pipeline |
| **Yarn** | 1.22+ | Gestor de paquetes JS |
| **Docker** *(opcional)* | 20+ | Para despliegue containerizado |

### ⚠️ Nota Importante: PostgreSQL en Puerto 5433

Este proyecto está configurado para usar PostgreSQL en el **puerto 5433** en lugar del puerto estándar 5432. Esto permite ejecutar la aplicación junto a otra instancia de PostgreSQL si ya tienes una corriendo.

Asegúrate de:
- Tener PostgreSQL corriendo en el puerto 5433
- O modificar `config/database.yml` para usar el puerto que prefieras

---

## 🛠️ Instalación Detallada

### Paso 1: Clonar el Repositorio

```bash
git clone <url-del-repositorio>
cd roraima_app
```

### Paso 2: Instalar Ruby 3.2.2

#### Usando rbenv (recomendado):

```bash
# Instalar rbenv si no lo tienes
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/main/bin/rbenv-installer | bash

# Instalar Ruby 3.2.2
rbenv install 3.2.2
rbenv local 3.2.2

# Verificar instalación
ruby -v  # Debe mostrar ruby 3.2.2
```

#### Usando rvm:

```bash
# Instalar Ruby 3.2.2
rvm install 3.2.2
rvm use 3.2.2

# Verificar instalación
ruby -v
```

### Paso 3: Instalar y Configurar PostgreSQL

#### En Ubuntu/Debian:

```bash
sudo apt update
sudo apt install postgresql postgresql-contrib libpq-dev

# Iniciar servicio
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

#### Configurar puerto 5433:

Edita `/etc/postgresql/<version>/main/postgresql.conf`:

```conf
port = 5433
```

Reinicia PostgreSQL:

```bash
sudo systemctl restart postgresql
```

#### En macOS (con Homebrew):

```bash
brew install postgresql@15

# Iniciar en puerto 5433
brew services start postgresql@15
# Modificar puerto en: /opt/homebrew/var/postgresql@15/postgresql.conf
```

### Paso 4: Instalar Dependencias de Ruby y Node.js

```bash
# Instalar gemas de Ruby
bundle install

# Instalar Node.js (si no lo tienes)
# Ubuntu/Debian:
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# macOS:
brew install node

# Instalar Yarn
npm install -g yarn

# Instalar paquetes Node.js
yarn install
```

### Paso 5: Configurar la Base de Datos

```bash
# Crear las bases de datos
rails db:create

# Ejecutar migraciones
rails db:migrate

# Opcional: Si hay problemas, intenta esto:
# rails db:drop db:create db:migrate
```

### Paso 6: Sembrar Datos de Prueba

```bash
rails db:seed
```

Esto creará:
- 16 regiones de Chile
- 345+ comunas asociadas a sus regiones
- 3 usuarios de prueba (1 admin + 2 clientes)
- 15 paquetes de ejemplo

### Paso 7: Iniciar el Servidor de Desarrollo

```bash
# Opción A: Con Foreman (recomendado - incluye Tailwind CSS watch)
bin/dev

# Opción B: Manualmente en terminales separadas
# Terminal 1:
rails server

# Terminal 2:
rails tailwindcss:watch
```

Accede a **http://localhost:3000** en tu navegador.

---

## 🏗️ Tecnologías Principales

### Backend

| Tecnología | Versión | Propósito |
|------------|---------|-----------|
| **Ruby** | 3.2.2 | Lenguaje de programación |
| **Rails** | 7.1.5 | Framework web |
| **PostgreSQL** | Latest | Base de datos relacional |
| **Puma** | Latest | Servidor web |
| **Devise** | Latest | Autenticación de usuarios |
| **Pundit** | Latest | Autorización basada en políticas |
| **Pagy** | ~6.0 | Paginación de alto rendimiento |

### Frontend

| Tecnología | Versión | Propósito |
|------------|---------|-----------|
| **Tailwind CSS** | Latest | Framework CSS utility-first |
| **Hotwire Turbo** | Latest | SPA-like sin escribir JavaScript |
| **Stimulus** | Latest | Framework JavaScript modesto |
| **Import Maps** | Latest | Gestión de módulos JS sin bundler |
| **Inter Font** | ^5.2.8 | Tipografía moderna |

### Testing

| Tecnología | Versión | Propósito |
|------------|---------|-----------|
| **Minitest** | Latest | Framework de testing (default Rails) |
| **FactoryBot** | ~6.0 | Creación de datos de prueba |
| **Capybara** | Latest | Tests de integración del navegador |
| **Selenium WebDriver** | Latest | Automatización del navegador |

### DevOps

| Tecnología | Propósito |
|------------|-----------|
| **Docker** | Containerización para despliegue |
| **Foreman** | Gestión de procesos en desarrollo |

---

## ⚙️ Variables de Entorno

### Variables para Desarrollo

En desarrollo, la mayoría de configuraciones tienen valores por defecto. Opcionalmente puedes crear un archivo `.env` (ver `.env.example`):

```bash
# Base de datos
DATABASE_URL=postgresql://postgres@localhost:5433/roraima_app_development

# Rails (opcional en desarrollo)
RAILS_MAX_THREADS=5
```

### Variables para Producción

En producción, **debes configurar** estas variables:

| Variable | Obligatorio | Descripción | Ejemplo |
|----------|-------------|-------------|---------|
| `RORAIMA_APP_DATABASE_PASSWORD` | ✅ Sí | Contraseña de PostgreSQL | `super_secret_password` |
| `RAILS_MASTER_KEY` | ✅ Sí | Llave para desencriptar credentials | Se genera automáticamente |
| `SECRET_KEY_BASE` | ✅ Sí | Secret para sesiones (puede estar en credentials) | `rails secret` |
| `RAILS_MAX_THREADS` | ⚠️ Recomendado | Tamaño del pool de conexiones | `5` |
| `RAILS_LOG_TO_STDOUT` | ⚠️ Recomendado | Logs a stdout para Docker | `true` |
| `RAILS_SERVE_STATIC_FILES` | ⚠️ Recomendado | Servir assets estáticos | `true` |

### 🔐 Archivo Master Key

El archivo `config/master.key` es **crítico** y **NO debe subirse a git**. Este archivo:
- Desencripta `config/credentials.yml.enc`
- Contiene secretos de la aplicación
- Se genera automáticamente con `rails new`

Si perdiste el `master.key`:

```bash
# Eliminar credentials encriptados
rm config/credentials.yml.enc

# Regenerar
EDITOR="code --wait" rails credentials:edit
```

Para ver el archivo `.env.example` completo, consulta el archivo en la raíz del proyecto.

---

## 🗄️ Base de Datos

### Configuración

- **Motor**: PostgreSQL
- **Puerto**: 5433 (no estándar, modificable en `config/database.yml`)
- **Encoding**: UTF-8
- **Pool de conexiones**: 5 (ajustable con `RAILS_MAX_THREADS`)

### Datos Iniciales (Seeds)

Al ejecutar `rails db:seed`, se carga:

✅ **16 regiones de Chile**: Arica y Parinacota, Tarapacá, Antofagasta, Atacama, Coquimbo, Valparaíso, Metropolitana, O'Higgins, Maule, Ñuble, Biobío, Araucanía, Los Ríos, Los Lagos, Aysén, Magallanes

✅ **345+ comunas**: Todas las comunas de Chile asociadas a sus regiones respectivas

✅ **Usuarios de prueba**: 1 admin + 2 clientes con paquetes de ejemplo

---

## 👤 Credenciales de Acceso (Desarrollo)

Después de ejecutar `rails db:seed`, puedes acceder con estas credenciales:

### 🔑 Usuario Administrador

- **Email**: `admin@paqueteria.com`
- **Contraseña**: `password123`
- **Permisos**: Acceso completo a todos los paquetes y usuarios

### 🔑 Usuarios Clientes

| Email | Contraseña | Paquetes Asignados |
|-------|------------|-------------------|
| `customer1@example.com` | `password123` | 5 paquetes |
| `customer2@example.com` | `password123` | 3 paquetes |
| `customer3@example.com` | `password123` | 2 paquetes |

### ⚠️ Advertencia de Seguridad

**NUNCA uses estas credenciales en producción.** Antes de desplegar:

1. Elimina o desactiva los usuarios de seed
2. Cambia todas las contraseñas
3. Configura autenticación de dos factores (2FA) si es posible
4. Implementa políticas de contraseñas robustas

---

## 🏃 Cómo Ejecutar en Local

Tienes 3 opciones para ejecutar la aplicación localmente:

### Opción 1: Con Foreman (⭐ Recomendada)

Foreman ejecuta múltiples procesos simultáneamente según `Procfile.dev`:

```bash
bin/dev
```

Esto inicia:
- 🌐 Rails server en `localhost:3000`
- 🎨 Tailwind CSS en modo watch (recompila CSS automáticamente)

**Ventaja**: Un solo comando, live reload de CSS

### Opción 2: Manualmente (dos terminales)

Si prefieres mayor control o no tienes Foreman:

**Terminal 1** - Rails Server:
```bash
rails server
# o
rails s
```

**Terminal 2** - Tailwind CSS Watch:
```bash
rails tailwindcss:watch
```

Accede a **http://localhost:3000**

```
## 🧪 Cómo Correr Pruebas

La aplicación usa **Minitest** con **FactoryBot** para generar datos de prueba.

### Ejecutar Todas las Pruebas

```bash
# Ejecutar suite completa
rails test

# Con más detalle
rails test -v
```

### Ejecutar Pruebas Específicas

```bash
# Tests de modelos
rails test test/models

# Un archivo específico
rails test test/models/package_test.rb

# Una prueba específica por línea
rails test test/models/package_test.rb:15

# Tests de controladores
rails test test/controllers

# Tests de sistema (navegador)
rails test:system
```

### Tests de Sistema (E2E)

Los tests de sistema usan **Capybara** con **Selenium WebDriver** para simular interacciones reales del navegador:

```bash
# Ejecutar todos los system tests
rails test:system

# Un archivo específico
rails test test/system/packages_test.rb
```

**Nota**: Necesitas tener Chrome o Chromium instalado para los tests de sistema.

### Preparar Base de Datos de Testing

Si tienes problemas con la BD de test:

```bash
# Recrear la BD de testing
RAILS_ENV=test rails db:reset

# O más seguro:
RAILS_ENV=test rails db:drop db:create db:migrate db:seed
```

### FactoryBot - Factories Disponibles

El proyecto incluye factories para todos los modelos:

```ruby
# En tus tests, puedes usar:
FactoryBot.create(:user)                    # Usuario customer por defecto
FactoryBot.create(:user, :admin)            # Usuario admin
FactoryBot.create(:user, :with_packages)    # Usuario con paquetes
FactoryBot.create(:package)                 # Paquete con asociaciones
FactoryBot.create(:region)                  # Región
FactoryBot.create(:commune)                 # Comuna
```

### Helpers de Testing

El proyecto incluye helpers personalizados en `test/test_helper.rb`:

```ruby
# Iniciar sesión como admin en tests
sign_in_as_admin

# Iniciar sesión como usuario customer
sign_in_as_user(user)
```

### Coverage (Opcional)

Para medir cobertura de código, agrega `simplecov` al `Gemfile`:

```ruby
# Gemfile
group :test do
  gem 'simplecov', require: false
end
```

Y en `test/test_helper.rb`:

```ruby
require 'simplecov'
SimpleCov.start 'rails'
```


## 📁 Estructura del Proyecto

```
roraima_app/
├── app/
│   ├── controllers/
│   │   ├── admin/                    # Namespace de administradores
│   │   │   ├── base_controller.rb    # Autenticación admin
│   │   │   ├── packages_controller.rb
│   │   │   ├── users_controller.rb
│   │   │   └── communes_controller.rb
│   │   ├── customers/                # Namespace de clientes
│   │   │   ├── packages_controller.rb
│   │   │   ├── profiles_controller.rb
│   │   │   └── communes_controller.rb
│   │   ├── application_controller.rb
│   │   └── customers_controller.rb
│   ├── models/
│   │   ├── user.rb                   # Devise + roles (admin/customer)
│   │   ├── package.rb                # Lógica de paquetes
│   │   ├── region.rb                 # Regiones de Chile
│   │   └── commune.rb                # Comunas de Chile
│   ├── policies/                     # Pundit authorization
│   │   ├── application_policy.rb
│   │   ├── package_policy.rb
│   │   └── user_policy.rb
│   ├── views/
│   │   ├── admin/                    # Vistas de administración
│   │   ├── customers/                # Vistas de clientes
│   │   ├── devise/                   # Vistas de autenticación
│   │   ├── layouts/
│   │   └── shared/
│   ├── assets/
│   │   ├── images/
│   │   └── stylesheets/
│   └── javascript/
│       ├── controllers/              # Stimulus controllers
│       └── application.js
├── config/
│   ├── database.yml                  # Configuración de BD (puerto 5433)
│   ├── routes.rb                     # Rutas de la aplicación
│   ├── credentials.yml.enc           # Secretos encriptados
│   └── environments/
│       ├── development.rb
│       ├── test.rb
│       └── production.rb
├── db/
│   ├── migrate/                      # Migraciones
│   ├── seeds.rb                      # Datos iniciales (regiones/comunas)
│   └── schema.rb                     # Schema actual
├── test/
│   ├── controllers/
│   ├── models/
│   ├── system/                       # Tests E2E con Capybara
│   ├── factories/                    # FactoryBot factories
│   └── test_helper.rb
├── bin/
│   ├── dev                           # Script Foreman para desarrollo
│   ├── docker-entrypoint             # Entrypoint de Docker
│   └── setup                         # Setup inicial del proyecto
├── Dockerfile                        # Configuración Docker
├── Procfile.dev                      # Procesos de desarrollo
├── Gemfile                           # Dependencias Ruby
├── package.json                      # Dependencias Node.js
└── README.md                         # Este archivo
```

### Organización por Namespaces

La aplicación usa **namespaces** para separar la lógica de admin y clientes:

- **`Admin::`**: Controladores, vistas y rutas para administradores
  - Gestión completa de usuarios
  - Gestión de todos los paquetes del sistema
  - Sin restricciones de autorización

- **`Customers::`**: Controladores, vistas y rutas para clientes
  - Solo pueden ver/editar sus propios paquetes
  - Perfil de usuario editable
  - Cancelación de paquetes propios

### Políticas de Autorización (Pundit)

Las políticas definen quién puede hacer qué:

```ruby
# app/policies/package_policy.rb
class PackagePolicy < ApplicationPolicy
  def index?
    true  # Todos pueden ver el índice (filtrado por scope)
  end

  def create?
    true  # Todos pueden crear paquetes
  end

  def update?
    user.admin? || record.user == user  # Admin o dueño
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all  # Admin ve todos
      else
        scope.where(user: user)  # Clientes solo los suyos
      end
    end
  end
end
```

---

## 🎯 Características Principales

### 🔐 Autenticación y Autorización

- **Devise** para autenticación completa (login, logout, reset password)
- **Pundit** para autorización granular basada en políticas
- Sistema de **roles**: Admin y Customer
- Redirects automáticos según rol después de login

### 📦 Gestión de Paquetes

- **CRUD completo** con validaciones robustas
- Campos: nombre cliente, empresa, dirección, descripción, teléfono
- Selección de **región y comuna** con filtros dinámicos
- Marcado de **paquetes de devolucion** (`exchange`)
- Programación de **fecha de retiro** (`pickup_date`)
- **Estados**: Activo, Cancelado
- **Cancelación** con registro de razón y timestamp

### 🗺️ Cobertura Geográfica

- **16 regiones** de Chile
- **345+ comunas** asociadas
- Selector dinámico: seleccionar región → carga comunas correspondientes (AJAX)
- Base de datos completa incluida en seeds

### 🔍 Búsqueda y Filtrado

- Búsqueda por nombre de cliente, empresa, dirección
- Filtros por región, comuna, estado
- **13 índices de rendimiento** para queries rápidas
- Paginación con **Pagy** (25 items por página)

### 🎨 Interfaz de Usuario

- Diseño moderno con **Tailwind CSS**
- **Hotwire (Turbo)** para SPA-like experience sin escribir JS
- **Stimulus** para interacciones específicas
- Responsive design
- Tipografía Inter

### 📤 Carga Masiva de Paquetes

- **Importación masiva** desde archivos CSV/XLSX
- **Validación automática** de datos con reporte de errores detallado
- **Trazabilidad completa**: cada paquete vinculado a su carga de origen
- **Procesamiento asíncrono** con actualizaciones en tiempo real
- **Estadísticas de carga**: filas procesadas, exitosas, fallidas
- **Auditoría**: rastrear qué archivo creó cada paquete
- **Compatibilidad**: paquetes manuales y masivos conviven sin problemas

### 🚗 Sistema de Drivers y Zonas de Reparto

- **Driver Model (STI)**: Conductores heredan de User usando Single Table Inheritance
- **Zone Model**: Zonas geográficas con comunas asignadas en JSONB
- **Gestión completa de vehículos**: Patente chilena, modelo, capacidad
- **Asignación de zonas**: Cada driver puede tener una zona asignada
- **Portal para drivers**: Vista de paquetes asignados y cambio de estados
- **Validaciones de seguridad**: Solo drivers activos pueden ser asignados
- **CRUD completo**: Administración de drivers y zonas desde panel admin
- **40 tests**: Cobertura completa de Driver y Zone models (100% pasando)

### 📊 Dashboard

- Admin: vista de todos los paquetes del sistema
- Cliente: vista de sus propios paquetes
- Estadísticas rápidas (total de paquetes, activos, cancelados)

---

## 📤 Carga Masiva y Trazabilidad

### Visión General

El sistema incluye funcionalidad de **carga masiva de paquetes** que permite crear múltiples paquetes simultáneamente desde archivos CSV/XLSX. Cada paquete creado mediante carga masiva mantiene una **relación de trazabilidad** con su carga de origen.

### Relación BulkUpload ↔ Package

Desde **Noviembre 2025**, todos los paquetes creados mediante carga masiva se vinculan automáticamente con su `BulkUpload` de origen:

```ruby
# Modelo Package
belongs_to :bulk_upload, optional: true

# Modelo BulkUpload
has_many :packages, dependent: :nullify
```

**Características importantes:**
- ✅ `optional: true` - Los paquetes creados manualmente NO requieren `bulk_upload_id`
- ✅ `dependent: :nullify` - Si se elimina un BulkUpload, los paquetes permanecen pero su `bulk_upload_id` se establece en NULL
- ✅ **Retrocompatibilidad total** - Paquetes existentes sin `bulk_upload_id` siguen funcionando normalmente

### Estructura de Base de Datos

**Migración aplicada:** `20251125031149_add_bulk_upload_ref_to_packages.rb`

```ruby
add_reference :packages, :bulk_upload, foreign_key: true, index: true
```

Esto crea:
- Columna `bulk_upload_id` (bigint, nullable)
- Foreign key constraint hacia `bulk_uploads.id`
- Índice para optimizar consultas de trazabilidad

### Servicio de Carga Masiva

El `BulkPackageUploadService` asigna automáticamente el `bulk_upload_id` durante el procesamiento:

```ruby
# app/services/bulk_package_upload_service.rb
def build_package_params(row_number, row_data)
  # ... transformación de datos ...

  params[:bulk_upload_id] = bulk_upload.id  # ← Asignación automática

  params
end
```

### Ejemplos de Uso

#### Consultar Paquetes de una Carga Específica

```ruby
# Obtener una carga masiva
bulk_upload = BulkUpload.find(29)

# Ver todos los paquetes creados por esta carga
bulk_upload.packages
# => [#<Package id: 101, tracking_code: "PKG-...", bulk_upload_id: 29>, ...]

# Contar paquetes
bulk_upload.packages.count
# => 150

# Filtrar por estado
bulk_upload.packages.where(status: :entregado)
bulk_upload.packages.where(status: [:en_camino, :reprogramado])

# Ver estadísticas
bulk_upload.packages.group(:status).count
# => {"pendiente_retiro"=>120, "en_camino"=>25, "entregado"=>5}
```

#### Rastrear el Origen de un Paquete

```ruby
# Obtener un paquete
package = Package.find(638)

# Ver de qué carga masiva proviene
package.bulk_upload
# => #<BulkUpload id: 29, user_id: 5, status: "completed", ...>

# Si fue creado manualmente
package.bulk_upload
# => nil (sin carga asociada)

# Verificar si proviene de carga masiva
package.bulk_upload_id.present?  # => true/false
```

#### Auditoría y Reportes

```ruby
# Paquetes creados manualmente vs carga masiva
manual_packages = Package.where(bulk_upload_id: nil)
bulk_packages = Package.where.not(bulk_upload_id: nil)

puts "Paquetes manuales: #{manual_packages.count}"
puts "Paquetes por carga masiva: #{bulk_packages.count}"

# Listar todas las cargas con sus métricas
BulkUpload.recent.each do |upload|
  puts "Upload ##{upload.id} - #{upload.created_at.strftime('%d/%m/%Y')}"
  puts "  Total procesado: #{upload.total_rows}"
  puts "  Exitosos: #{upload.successful_rows}"
  puts "  Fallidos: #{upload.failed_rows}"
  puts "  Paquetes actuales: #{upload.packages.count}"
  puts "  Tasa éxito: #{upload.success_rate}%"
end

# Encontrar cargas con errores para investigación
BulkUpload.where("failed_rows > ?", 0).each do |upload|
  puts "Carga ##{upload.id} tuvo #{upload.failed_rows} errores"
  puts upload.formatted_errors.join("\n")
end
```

#### Análisis de Desempeño por Carga

```ruby
# Comparar tasas de entrega entre diferentes cargas masivas
BulkUpload.completed.each do |upload|
  total = upload.packages.count
  entregados = upload.packages.where(status: :entregado).count
  tasa_entrega = (entregados.to_f / total * 100).round(2)

  puts "Carga ##{upload.id}: #{tasa_entrega}% entregado (#{entregados}/#{total})"
end
```

### Casos de Uso

#### 1. Debugging de Cargas Problemáticas
Si una carga masiva tuvo problemas, puedes identificar exactamente qué paquetes fueron afectados:

```ruby
bulk_upload = BulkUpload.find(29)
problematic_packages = bulk_upload.packages.where(status: [:devolucion, :cancelado])
```

#### 2. Reportes para Clientes
Generar reportes específicos de una carga:

```ruby
bulk_upload = BulkUpload.find(29)
user = bulk_upload.user

puts "Reporte para #{user.email}"
puts "Fecha de carga: #{bulk_upload.created_at}"
puts "Paquetes entregados: #{bulk_upload.packages.where(status: :entregado).count}"
puts "Paquetes en tránsito: #{bulk_upload.packages.where(status: [:en_bodega, :en_camino]).count}"
```

#### 3. Validación de Integridad
Verificar que la cantidad de paquetes coincide con los registros:

```ruby
bulk_upload = BulkUpload.find(29)

if bulk_upload.successful_rows != bulk_upload.packages.count
  puts "⚠️ ALERTA: Discrepancia detectada"
  puts "Registrados como exitosos: #{bulk_upload.successful_rows}"
  puts "Paquetes reales: #{bulk_upload.packages.count}"
end
```

### Beneficios de la Trazabilidad

1. **Auditoría Completa**: Saber exactamente qué archivo/carga creó cada paquete
2. **Debugging Eficiente**: Identificar problemas relacionados a cargas específicas
3. **Reportes Precisos**: Generar estadísticas por carga masiva
4. **Historial**: Mantener registro completo de todas las cargas realizadas
5. **Integridad de Datos**: Validar que los números coincidan entre procesamiento y resultado

### Archivos Relacionados

| Archivo | Descripción |
|---------|-------------|
| `app/models/package.rb` | Modelo con relación `belongs_to :bulk_upload` |
| `app/models/bulk_upload.rb` | Modelo con relación `has_many :packages` |
| `app/services/bulk_package_upload_service.rb` | Servicio que asigna `bulk_upload_id` |
| `db/migrate/20251125031149_add_bulk_upload_ref_to_packages.rb` | Migración que crea la columna |

### Notas Técnicas

- La columna `bulk_upload_id` es **nullable** por diseño para mantener compatibilidad
- Los índices están optimizados para consultas de trazabilidad
- La relación `dependent: :nullify` previene eliminación accidental de paquetes
- El servicio asigna automáticamente el ID sin intervención manual

---

## 🚗 Sistema de Drivers y Zonas de Reparto

### Visión General

El sistema incluye funcionalidad completa para gestionar **conductores (drivers)** y **zonas de reparto** utilizando patrones avanzados de Rails como Single Table Inheritance (STI) y almacenamiento JSONB para flexibilidad.

### Arquitectura

#### Driver Model - Single Table Inheritance (STI)

Los drivers heredan de `User` manteniendo todos los atributos y métodos mientras agregan funcionalidad específica:

```ruby
User (Tabla base)
├── User (type: nil) - Admin/Customer
└── Driver (type: 'Driver') - Conductores
```

**Campos específicos de Driver:**
- `vehicle_plate` (String) - Patente chilena (ABCD12 o AB1234)
- `vehicle_model` (String) - Modelo del vehículo
- `vehicle_capacity` (Integer) - Capacidad en kg
- `assigned_zone_id` (BigInt) - FK a tabla zones

#### Zone Model - JSONB Storage

Las zonas agrupan comunas geográficamente usando JSONB para flexibilidad:

```ruby
class Zone < ApplicationRecord
  belongs_to :region
  has_many :drivers, foreign_key: :assigned_zone_id

  # Comunas almacenadas como array JSONB de IDs
  # communes: [123, 456, 789]
end
```

### Funcionalidades Principales

#### 1. Gestión de Drivers (Admin)

**Ruta:** `/admin/drivers`

- CRUD completo de conductores
- Validación de patente chilena (ABCD12 o AB1234)
- Asignación de zona geográfica
- Vista de paquetes asignados
- Estadísticas diarias (entregas hoy, pendientes)
- Filtros por zona y estado (activo/inactivo)

**Validaciones:**
```ruby
validates :vehicle_plate,
  presence: true,
  uniqueness: true,
  format: { with: /\A[A-Z]{2}\d{4}|[A-Z]{4}\d{2}\z/ }

validates :vehicle_capacity, numericality: { greater_than: 0 }
```

#### 2. Gestión de Zonas (Admin)

**Ruta:** `/admin/zones`

- CRUD completo de zonas
- Asignación de múltiples comunas (JSONB)
- Selector dinámico de comunas por región (AJAX)
- Vista de drivers asignados
- Listado de comunas incluidas

#### 3. Portal de Driver

**Ruta:** `/drivers`

- Vista de paquetes asignados
- Cambio de estado de paquetes
- Estadísticas diarias
- Restricción: solo ve paquetes asignados a él

### Sistema de Asignación

**Flujo de asignación de paquetes:**

1. Admin asigna driver a paquete desde `/admin/packages`
2. Sistema valida que el usuario sea Driver (no customer/admin)
3. Sistema valida que el driver esté activo
4. Paquete se asigna y aparece en portal del driver
5. Driver puede cambiar estados según flujo permitido

**Validaciones de seguridad:**
```ruby
# Solo drivers activos pueden ser asignados
unless courier.is_a?(Driver)
  @errors << "El usuario no es un conductor válido"
  return false
end

unless courier.active?
  @errors << "No se puede asignar un conductor inactivo"
  return false
end
```

### Zonas de Ejemplo (Seeds)

El sistema incluye 4 zonas pre-configuradas para Región Metropolitana:

- **Zona Norte RM**: Huechuraba, Conchalí, Independencia, Recoleta, Quilicura, Colina, Lampa
- **Zona Centro RM**: Santiago, Providencia, Las Condes, Vitacura, Ñuñoa, La Reina
- **Zona Sur RM**: La Florida, Puente Alto, La Pintana, San Bernardo, El Bosque
- **Zona Oeste RM**: Maipú, Pudahuel, Cerrillos, Lo Prado, Renca, Cerro Navia

### Drivers de Ejemplo (Seeds)

```ruby
# Driver 1
Email: driver1@example.com
Vehículo: Toyota Hiace 2020 (AABB12)
Capacidad: 1500 kg
Zona: Zona Norte RM

# Driver 2
Email: driver2@example.com
Vehículo: Hyundai H100 2021 (CCDD34)
Capacidad: 1200 kg
Zona: Zona Centro RM
```

### Ejemplos de Uso

#### Consultar Drivers por Zona

```ruby
# Obtener una zona
zone = Zone.find_by(name: "Zona Norte RM")

# Ver todos los drivers asignados
zone.drivers
# => [#<Driver id: 10, email: "driver1@...", vehicle_plate: "AABB12">, ...]

# Drivers activos en esa zona
zone.drivers.active
```

#### Paquetes Asignados a un Driver

```ruby
# Obtener un driver
driver = Driver.find_by(email: "driver1@example.com")

# Entregas de hoy
driver.today_deliveries
# => [#<Package>, #<Package>]

# Pendientes (in_transit + rescheduled)
driver.pending_deliveries
# => [#<Package>, #<Package>, #<Package>]

# Todos los paquetes asignados
driver.assigned_packages
```

#### Asignar Paquete a Driver

```ruby
# Desde el servicio de estado
package = Package.find(123)
driver = Driver.find(10)

service = PackageStatusService.new(package, current_user)
service.assign_courier(driver.id)
# => true (si validaciones pasan)
```

### Seguridad y Permisos

**DriverPolicy:**
- Solo admins pueden crear/editar drivers
- Drivers pueden ver solo su propia información
- Customers no pueden ver drivers

**ZonePolicy:**
- Solo admins pueden gestionar zonas
- Drivers/Customers no tienen acceso

**PackagePolicy:**
- Solo admins pueden asignar drivers a paquetes
- Drivers pueden cambiar estados solo de paquetes asignados a ellos

### Testing

El sistema incluye tests exhaustivos:

**Driver Model (28 tests):**
- STI funcionamiento
- Validaciones de vehículo
- Formato de patente chilena
- Asociaciones con zonas
- Asignación de paquetes
- Scopes active/inactive

**Zone Model (12 tests):**
- Validaciones de nombre único
- Asociaciones con region y drivers
- Almacenamiento JSONB de comunas
- Métodos de instancia

```bash
# Ejecutar tests de drivers y zonas
bin/rails test test/models/driver_test.rb
# => 28 runs, 111 assertions, 0 failures

bin/rails test test/models/zone_test.rb
# => 12 runs, 31 assertions, 0 failures
```

### Archivos Creados

**Modelos:**
- `app/models/driver.rb`
- `app/models/zone.rb`

**Controladores:**
- `app/controllers/admin/drivers_controller.rb`
- `app/controllers/admin/zones_controller.rb`

**Políticas:**
- `app/policies/driver_policy.rb`
- `app/policies/zone_policy.rb`

**Vistas:**
- `app/views/admin/drivers/*` (5 archivos)
- `app/views/admin/zones/*` (5 archivos)

**Tests:**
- `test/models/driver_test.rb`
- `test/models/zone_test.rb`
- `test/factories/drivers.rb`
- `test/factories/zones.rb`

**Migraciones:**
- `20251125132343_add_type_to_users.rb` (STI)
- `20251125132344_create_zones.rb`
- `20251125132345_add_driver_fields_to_users.rb`
- `20251125132346_migrate_driver_users_to_sti.rb`

### Ventajas del Diseño

**Single Table Inheritance (STI):**
- Una sola tabla, evita joins complejos
- Herencia natural de User
- Polimorfismo: `user.is_a?(Driver)` funciona perfecto
- Scopes compartidos

**JSONB para Comunas:**
- Flexibilidad para agregar/quitar comunas
- No requiere tabla intermedia
- Queries eficientes con índices PostgreSQL
- Simplicidad en el modelo

### Documentación Completa

Para detalles completos de implementación, ver:
- `SISTEMA_DRIVERS_ZONAS.md` - Documentación técnica completa

---

## 📝 Licencia

Este proyecto está licenciado bajo la [MIT License](https://opensource.org/licenses/MIT).

```
MIT License

Copyright (c) 2025 [Tu Nombre/Empresa]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```


---

<div align="center">

**¿Tienes preguntas?** Abre un [issue](../../issues) o contacta al equipo.

⭐ Si este proyecto te fue útil, considera darle una estrella en GitHub

</div>
