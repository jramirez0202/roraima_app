# Roraima Delivery App

![Ruby Version](https://img.shields.io/badge/ruby-3.2.2-red.svg)
![Rails Version](https://img.shields.io/badge/rails-7.1.5-red.svg)
![PostgreSQL](https://img.shields.io/badge/postgresql-latest-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

> Sistema de gestión de paquetería diseñado para el mercado chileno con cobertura nacional completa.

---

## 🚀 Quick Start

```bash
# Clonar repositorio
git clone <url-del-repositorio>
cd roraima_app

# Instalar dependencias
bundle install

# Configurar base de datos (puerto 5433)
rails db:setup

# Iniciar servidor (Rails + Tailwind CSS watch)
bin/dev
```

**Acceso:** http://localhost:3000

**Credenciales de prueba:**
- **Admin:** `admin@roraima.cl` / `password123`
- **Customer:** `cliente@empresa.com` / `password123`
- **Driver:** `conductor@roraima.cl` / `password123`

---

## 📚 Documentación Completa

Este README es una introducción rápida. Para documentación detallada, consulta:

### 📖 [Índice de Documentación](./docs/index.md)

#### Guías por Tema

- **[Setup Local](./docs/setup/local.md)** - Instalación paso a paso en desarrollo
- **[Setup Docker](./docs/setup/docker.md)** - Instalación con contenedores
- **[Setup Producción](./docs/setup/production.md)** - Deployment a Heroku o VPS

- **[Arquitectura](./docs/architecture/overview.md)** - Visión general del sistema
- **[Decisiones](./docs/architecture/decisions.md)** - ADRs (Architecture Decision Records)
- **[Diagramas](./docs/architecture/diagrams.md)** - ERD, flujos, arquitectura

- **[Carga Masiva](./docs/bulk/carga-masiva.md)** - Guía de uso CSV/XLSX
- **[Formato CSV](./docs/bulk/formato-csv.md)** - Especificación detallada
- **[Validaciones](./docs/bulk/validaciones.md)** - Proceso de validación

- **[Sistema de Estados](./docs/operations/estados.md)** - Máquina de estados de paquetes
- **[Rutas](./docs/operations/rutas.md)** - Namespacing y controladores
- **[Cierres de Ruta](./docs/operations/cierres.md)** - 🚧 Planificado

- **[Errores Comunes](./docs/troubleshooting/errores-comunes.md)** - Soluciones rápidas
- **[Logs y Monitoreo](./docs/troubleshooting/logs.md)** - Debugging y monitoreo

- **[Glosario](./docs/glossary.md)** - Terminología del proyecto
- **[CLAUDE.md](./CLAUDE.md)** - Guía completa para desarrollo con AI

---

## 🎯 Descripción del Proyecto

**Roraima Delivery App** es un sistema completo de gestión de paquetería desarrollado específicamente para el mercado chileno. La aplicación permite administrar y rastrear paquetes de entrega con una cobertura geográfica completa de las 16 regiones de Chile y sus 345+ comunas.

### Características Destacadas

✅ **Sistema de Roles:** Admin, Customer, Driver con autorización granular (Pundit)
✅ **Carga Masiva:** Importación CSV/XLSX con validación y trazabilidad completa
✅ **Máquina de Estados:** 8 estados con transiciones controladas y historial inmutable (JSONB)
✅ **Drivers y Zonas:** STI para conductores, zonas geográficas con JSONB
✅ **Cobertura Nacional:** 16 regiones, 345+ comunas de Chile
✅ **Búsqueda Rápida:** Índice trigram (pg_trgm) para tracking codes
✅ **Background Jobs:** Sidekiq para procesamiento asíncrono
✅ **Generación de Etiquetas:** PDFs con QR codes (Prawn)
✅ **Interfaz Moderna:** Tailwind CSS + Turbo + Stimulus

---

## 🏗️ Stack Tecnológico

### Backend
- **Ruby:** 3.2.2
- **Rails:** 7.1.5
- **PostgreSQL:** 12+ (Puerto **5433**)
- **Sidekiq:** 7.0 (background jobs)
- **Devise:** Autenticación
- **Pundit:** Autorización
- **Pagy:** Paginación

### Frontend
- **Tailwind CSS:** Utility-first CSS
- **Turbo:** SPA-like navigation
- **Stimulus:** JavaScript interactivity
- **ImportMap:** Sin build step

### Testing
- **Minitest:** Framework de testing
- **FactoryBot:** Test data
- **Capybara + Selenium:** E2E tests

---

## 📋 Requisitos Previos

| Requisito | Versión | Notas |
|-----------|---------|-------|
| **Ruby** | 3.2.2 | Usa rbenv o rvm |
| **Rails** | 7.1.5+ | Se instala con bundle |
| **PostgreSQL** | 12+ | **Puerto 5433** ⚠️ |
| **Redis** | 6+ | Para Sidekiq |
| **Node.js** | 18+ | Para importmaps |

### ⚠️ PostgreSQL en Puerto 5433

Este proyecto usa PostgreSQL en **puerto 5433** (no el estándar 5432). Ver [Setup Local](./docs/setup/local.md#configurar-puerto-5433) para configuración.

---

## 🛠️ Instalación

### Opción 1: Setup Tradicional

Ver **[Setup Local](./docs/setup/local.md)** para guía detallada paso a paso.

```bash
# Resumen rápido
bundle install
rails db:create db:migrate db:seed
bin/dev
```

### Opción 2: Docker

Ver **[Setup Docker](./docs/setup/docker.md)** para instalación con contenedores.

```bash
docker compose up
docker compose run web rails db:setup
```

---

## 🧪 Testing

```bash
# Suite completa
rails test

# Tests específicos
rails test test/models
rails test test/services
rails test:system

# Cobertura actual
# - 28 tests de Driver model ✅
# - 12 tests de Zone model ✅
# - 57 tests de PackageStatusService ✅
# - Tests de BulkPackageUploadService ✅
```

Ver más en [Testing](./docs/setup/local.md#verificar-instalación).

---

## 📦 Características Principales

### 🔐 Autenticación y Autorización
- **Devise** para autenticación
- **Pundit** para autorización basada en políticas
- 3 roles: Admin, Customer, Driver
- Redirects automáticos post-login

### 📦 Gestión de Paquetes
- **CRUD completo** con validaciones
- **Tracking code:** 14 dígitos únicos (PKG-XXXXXXXXXXXXXXXX)
- **Máquina de estados:** 8 estados con transiciones controladas
- **Historial inmutable:** JSONB append-only
- **Asignación de drivers:** Solo admins
- **Cambio de estados:** Admins y drivers asignados

Ver **[Sistema de Estados](./docs/operations/estados.md)** para detalles.

### 📤 Carga Masiva
- **CSV/XLSX:** Roo gem para parsing
- **Validación row-by-row:** Reporte detallado de errores
- **Normalización automática:** Teléfonos, comunas, montos
- **Procesamiento asíncrono:** Sidekiq background jobs
- **Trazabilidad:** `bulk_upload_id` en cada paquete
- **Broadcasting:** Turbo Streams cada 5 filas

Ver **[Carga Masiva](./docs/bulk/carga-masiva.md)** para guía completa.

### 🚗 Drivers y Zonas
- **STI (Single Table Inheritance):** Driver hereda de User
- **Campos de vehículo:** Patente, modelo, capacidad
- **Zonas geográficas:** JSONB array de comunas
- **Portal de driver:** Vista de paquetes asignados
- **Validaciones:** Solo drivers activos pueden ser asignados

Ver **[SISTEMA_DRIVERS_ZONAS.md](./SISTEMA_DRIVERS_ZONAS.md)** para documentación técnica completa.

### 🗺️ Cobertura Geográfica
- **16 regiones** de Chile
- **345+ comunas** asociadas
- **Base de datos completa** en seeds
- **Normalización de alias:** "Santiago Centro" → "Santiago"

### 🔍 Búsqueda y Filtrado
- **Índice trigram (pg_trgm):** Búsqueda rápida de tracking codes
- **Búsqueda parcial:** "PKG-861", "465", "2264" encuentra "PKG-86169301226465"
- **Filtros:** Estado, fecha, comuna, courier
- **Paginación:** Pagy (10 items/página)

### 📊 Dashboard
- **Admin:** Vista de todos los paquetes, gestión completa
- **Customer:** Vista de sus paquetes, carga masiva
- **Driver:** Paquetes asignados, cambio de estados

---

## 📁 Estructura del Proyecto

```
roraima_app/
├── app/
│   ├── controllers/
│   │   ├── admin/           # Admin namespace (require_admin!)
│   │   ├── customers/       # Customer namespace
│   │   └── drivers/         # Driver namespace (require_driver!)
│   ├── models/
│   │   ├── user.rb          # Base (Devise + roles)
│   │   ├── driver.rb        # STI subclass
│   │   ├── package.rb       # State machine
│   │   └── zone.rb          # JSONB communes
│   ├── policies/            # Pundit authorization
│   ├── services/            # Business logic
│   │   ├── bulk_package_upload_service.rb
│   │   ├── package_status_service.rb
│   │   └── label_generator_service.rb
│   └── views/
│       ├── admin/
│       ├── customers/
│       └── drivers/
├── docs/                    # 📚 Documentación organizada
│   ├── index.md
│   ├── architecture/
│   ├── setup/
│   ├── bulk/
│   ├── operations/
│   └── troubleshooting/
├── config/
│   ├── database.yml         # Puerto 5433 ⚠️
│   └── routes.rb
├── db/
│   ├── migrate/
│   └── seeds.rb
└── test/
    ├── models/
    ├── services/
    └── factories/
```

Ver **[Arquitectura](./docs/architecture/overview.md)** para diagrama completo.

---

## ⚙️ Variables de Entorno

### Desarrollo

La mayoría tienen defaults. Opcionalmente crea `.env`:

```bash
DATABASE_PASSWORD=roraima_dev_password
SIDEKIQ_USERNAME=admin
SIDEKIQ_PASSWORD=admin123
```

### Producción

```bash
RAILS_MASTER_KEY=<from config/master.key>
DATABASE_PASSWORD=<secure-password>
SECRET_KEY_BASE=<rails secret>
RAILS_ENV=production
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
```

Ver **[Setup Producción](./docs/setup/production.md)** para configuración completa.

---

## 🗄️ Base de Datos

### Seeds

`rails db:seed` carga:

- ✅ 16 regiones de Chile
- ✅ 345+ comunas
- ✅ 4 zonas de reparto (RM)
- ✅ 3 usuarios de prueba (admin, customer, driver)
- ✅ 4 drivers de ejemplo
- ✅ Paquetes de ejemplo

### Índices Importantes

```sql
-- Composite indexes para queries comunes
CREATE INDEX packages_on_user_id_and_status;
CREATE INDEX packages_on_status_and_assigned_courier_id;

-- Trigram index para búsqueda rápida
CREATE INDEX packages_on_tracking_code_trigram USING GIN (gin_trgm_ops);

-- STI index
CREATE INDEX users_on_type;
```

Ver **[Base de Datos](./docs/architecture/overview.md#base-de-datos)**.

---

## 🚦 Comenzar a Desarrollar

### Para Nuevos Desarrolladores

1. **Leer:** [Setup Local](./docs/setup/local.md)
2. **Entender:** [Arquitectura](./docs/architecture/overview.md)
3. **Estudiar:** [CLAUDE.md](./CLAUDE.md) - Guía completa de desarrollo

### Para Admins/Usuarios

1. **Carga Masiva:** [Guía de Carga Masiva](./docs/bulk/carga-masiva.md)
2. **Estados de Paquetes:** [Sistema de Estados](./docs/operations/estados.md)
3. **Troubleshooting:** [Errores Comunes](./docs/troubleshooting/errores-comunes.md)

### Para DevOps

1. **Deploy:** [Setup Producción](./docs/setup/production.md)
2. **Monitoreo:** [Logs y Monitoreo](./docs/troubleshooting/logs.md)
3. **Docker:** [Setup Docker](./docs/setup/docker.md)

---

## 📝 Comandos Útiles

```bash
# Desarrollo
bin/dev                      # Rails + Tailwind watch
rails console                # Console interactiva
rails db:reset               # Recrear BD desde cero

# Testing
rails test                   # Suite completa
rails test test/models       # Solo modelos
rails test:system            # E2E tests

# Database
rails db:migrate             # Ejecutar migraciones
rails db:seed                # Cargar seeds
rails db:rollback            # Rollback última migración

# Sidekiq
bundle exec sidekiq          # Iniciar worker
# Web UI: http://localhost:3000/sidekiq (admin only)

# Assets
rails tailwindcss:build      # Compilar Tailwind
rails assets:precompile      # Precompilar assets (producción)
```

---

## 🐛 Troubleshooting

### Problemas Comunes

| Error | Solución |
|-------|----------|
| `PG::ConnectionBad` | Verificar que PostgreSQL está en puerto 5433 |
| `pg_trgm not found` | `CREATE EXTENSION pg_trgm;` en PostgreSQL |
| CSS no aplica | Ejecutar `bin/dev` o `rails tailwindcss:watch` |
| Sidekiq no procesa | Verificar que Redis está corriendo |

Ver **[Errores Comunes](./docs/troubleshooting/errores-comunes.md)** para soluciones detalladas.

---

## 📚 Documentación Adicional

### Archivos Legacy (Referencia)

Estos archivos contienen documentación histórica útil pero la documentación principal está ahora en `/docs`:

- `CARGA_MASIVA_GUIA_RAPIDA.md` → Ver [docs/bulk/carga-masiva.md](./docs/bulk/carga-masiva.md)
- `SISTEMA_DRIVERS_ZONAS.md` → Ver [docs/architecture/decisions.md](./docs/architecture/decisions.md)
- `ANALISIS_ESTADO_PAQUETES.md` → Ver [docs/operations/estados.md](./docs/operations/estados.md)
- `README.DOCKER.md` → Ver [docs/setup/docker.md](./docs/setup/docker.md)

### CLAUDE.md

`CLAUDE.md` es la **guía maestra** para desarrollo con Claude Code. Contiene:
- Comandos esenciales
- Patrones de arquitectura
- Convenciones de código
- Gotchas y mejores prácticas

**Para desarrolladores:** Leer `CLAUDE.md` antes de hacer cambios.

---

## 🤝 Contribuir

1. Fork el proyecto
2. Crear feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit cambios (`git commit -m 'Add AmazingFeature'`)
4. Push al branch (`git push origin feature/AmazingFeature`)
5. Abrir Pull Request

### Guidelines

- Seguir convenciones de Rails
- Agregar tests para nuevas features
- Actualizar documentación en `/docs`
- Usar Pundit para autorización
- Extraer lógica compleja a servicios

---

## 📜 Licencia

Este proyecto está licenciado bajo la [MIT License](https://opensource.org/licenses/MIT).

```
MIT License

Copyright (c) 2025 Roraima Delivery

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

**¿Tienes preguntas?** Consulta la [documentación](./docs/index.md) o abre un [issue](../../issues)

⭐ Si este proyecto te fue útil, considera darle una estrella en GitHub

**[📚 Documentación Completa](./docs/index.md)** | **[🏗️ Arquitectura](./docs/architecture/overview.md)** | **[🚀 Setup](./docs/setup/local.md)** | **[🐛 Troubleshooting](./docs/troubleshooting/errores-comunes.md)**

</div>
