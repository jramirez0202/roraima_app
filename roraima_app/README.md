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

### 📊 Dashboard

- Admin: vista de todos los paquetes del sistema
- Cliente: vista de sus propios paquetes
- Estadísticas rápidas (total de paquetes, activos, cancelados)

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
