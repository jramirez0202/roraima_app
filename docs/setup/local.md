# Setup de Desarrollo Local

**Última actualización:** Diciembre 2025

Esta guía te ayudará a configurar el entorno de desarrollo local de Roraima Delivery en tu máquina.

## Requisitos Previos

### Software Necesario

- **Ruby:** 3.2.2
- **Rails:** 7.1.5
- **PostgreSQL:** 12+ (corriendo en puerto **5433**)
- **Redis:** Para Sidekiq (background jobs)
- **Node.js:** Para importmaps (opcional, sin build step)

### Instalación de Dependencias (Ubuntu/Debian)

```bash
# Ruby (recomendado: usar rbenv o RVM)
sudo apt install rbenv ruby-build
rbenv install 3.2.2
rbenv global 3.2.2

# PostgreSQL
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql

# Redis
sudo apt install redis-server
sudo systemctl start redis-server

# Librerías del sistema
sudo apt install libpq-dev build-essential
```

### Instalación de Dependencias (macOS)

```bash
# Usar Homebrew
brew install rbenv postgresql@15 redis

# Ruby
rbenv install 3.2.2
rbenv global 3.2.2

# Iniciar servicios
brew services start postgresql@15
brew services start redis
```

## Configuración del Proyecto

### 1. Clonar el Repositorio

```bash
git clone https://github.com/tu-usuario/roraima_delivery.git
cd roraima_delivery/roraima_app
```

### 2. Instalar Gemas

```bash
bundle install
```

Si tienes problemas con `pg` gem:

```bash
# Ubuntu/Debian
sudo apt install libpq-dev

# macOS
brew install postgresql@15
gem install pg -- --with-pg-config=/usr/local/opt/postgresql@15/bin/pg_config
```

### 3. Configurar Base de Datos

**IMPORTANTE:** El proyecto usa PostgreSQL en puerto **5433** (no el estándar 5432).

#### Crear el usuario de PostgreSQL

```bash
# Conectar a PostgreSQL como superusuario
sudo -u postgres psql

# Crear usuario roraima con contraseña
CREATE USER roraima WITH PASSWORD 'roraima_dev_password';
ALTER USER roraima CREATEDB;
\q
```

#### Configurar puerto 5433

Edita `/etc/postgresql/*/main/postgresql.conf`:

```conf
port = 5433
```

Reinicia PostgreSQL:

```bash
sudo systemctl restart postgresql
```

#### Verificar configuración

El archivo `config/database.yml` ya está configurado para puerto 5433:

```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  host: localhost
  port: 5433
  username: roraima
  password: <%= ENV['DATABASE_PASSWORD'] || 'roraima_dev_password' %>

development:
  <<: *default
  database: roraima_app_development

test:
  <<: *default
  database: roraima_app_test

production:
  <<: *default
  database: roraima_app_production
```

### 4. Crear y Preparar la Base de Datos

```bash
# Crear base de datos
rails db:create

# Ejecutar migraciones
rails db:migrate

# Cargar seeds (regiones, comunas, usuarios de prueba, zonas)
rails db:seed

# Para tests (preparar DB de test)
rails db:test:prepare
```

### 5. Configurar Credenciales

El proyecto usa Rails encrypted credentials:

```bash
# Editar credenciales (requiere EDITOR environment variable)
EDITOR=vim rails credentials:edit

# O con tu editor favorito
EDITOR="code --wait" rails credentials:edit
```

Contenido recomendado para `config/credentials.yml.enc`:

```yaml
secret_key_base: <generar con rails secret>

development:
  database_password: roraima_dev_password

production:
  database_password: <%= ENV['DATABASE_PASSWORD'] %>
  sidekiq_username: admin
  sidekiq_password: <%= ENV['SIDEKIQ_PASSWORD'] %>
```

### 6. Habilitar Extensión pg_trgm (Búsqueda Rápida)

```bash
# Conectar a la base de datos de desarrollo
psql -h localhost -p 5433 -U roraima roraima_app_development

# Crear extensión
CREATE EXTENSION IF NOT EXISTS pg_trgm;
\q
```

## Iniciar el Servidor de Desarrollo

### Opción 1: Script bin/dev (Recomendado)

Inicia Rails server + Tailwind CSS watch en paralelo:

```bash
bin/dev
```

Esto ejecuta:
- `rails server` en http://localhost:3000
- `rails tailwindcss:watch` (recompila CSS en tiempo real)

### Opción 2: Manualmente (Dos Terminales)

**Terminal 1:** Rails server

```bash
rails server
# Visita http://localhost:3000
```

**Terminal 2:** Tailwind CSS watch

```bash
rails tailwindcss:watch
```

### Iniciar Sidekiq (Background Jobs)

**Terminal 3:** Sidekiq

```bash
bundle exec sidekiq
```

Monitorear jobs en: http://localhost:3000/sidekiq (solo admins)

## Usuarios de Prueba (Seeds)

Después de `rails db:seed`, tendrás estos usuarios:

### Admin
- **Email:** `admin@roraima.cl`
- **Password:** `password123`
- **Permisos:** Acceso total al sistema

### Customers
- **Email:** `cliente@empresa.com`
- **Password:** `password123`
- **Empresa:** Cliente de Prueba

- **Email:** `cliente2@empresa.com`
- **Password:** `password123`

### Drivers
- **Email:** `conductor@roraima.cl`
- **Password:** `password123`
- **Vehículo:** Furgón Toyota Hiace, patente ABCD12
- **Zona:** Zona Norte (Huechuraba, Quilicura, Conchalí, Renca)

- **Email:** `conductor2@roraima.cl`
- **Password:** `password123`
- **Vehículo:** Camioneta Chevrolet D-MAX, patente EFGH34

## Verificar Instalación

### 1. Rails Console

```bash
rails console

# Verificar modelos
User.count
Package.count
Driver.count
Zone.count

# Verificar extensión pg_trgm
ActiveRecord::Base.connection.execute("SELECT extname FROM pg_extension WHERE extname = 'pg_trgm';").to_a
# Debe retornar [{"extname"=>"pg_trgm"}]
```

### 2. Ejecutar Tests

```bash
# Todos los tests
rails test

# Solo modelos
rails test test/models

# Solo servicios
rails test test/services

# Tests de sistema (E2E)
rails test:system
```

### 3. Acceder a la Aplicación

- **Home:** http://localhost:3000
- **Admin Panel:** http://localhost:3000/admin/packages
- **Customer Panel:** http://localhost:3000/customers/packages
- **Driver Panel:** http://localhost:3000/drivers/packages
- **Sidekiq UI:** http://localhost:3000/sidekiq

## Comandos Útiles de Desarrollo

### Base de Datos

```bash
# Recrear base de datos desde cero
rails db:reset

# Ejecutar migración específica
rails db:migrate:up VERSION=20251125132343

# Rollback última migración
rails db:rollback

# Ver estado de migraciones
rails db:migrate:status

# Abrir consola PostgreSQL
psql -h localhost -p 5433 -U roraima roraima_app_development
```

### Assets y Tailwind

```bash
# Recompilar assets
rails assets:precompile

# Limpiar assets compilados
rails assets:clobber

# Recompilar Tailwind CSS
rails tailwindcss:build

# Limpiar Tailwind CSS compilado
rails tmp:clear
```

### Consola Rails

```bash
# Consola normal
rails console

# Consola sandbox (rollback automático al salir)
rails console --sandbox

# Ejecutar código Ruby
rails runner "puts User.admin.count"
```

### Generadores

```bash
# Generar migración
rails generate migration AddFieldToModel field:type

# Generar modelo
rails generate model Package tracking_code:string

# Generar controlador
rails generate controller Admin::Packages

# Generar servicio (manual - crear archivo en app/services/)
```

## Solución de Problemas Comunes

### Puerto 5433 ya está en uso

```bash
# Ver qué proceso usa el puerto
sudo lsof -i :5433

# Matar proceso específico
kill -9 <PID>

# O cambiar puerto en config/database.yml (no recomendado)
```

### Error: `pg_trgm` extension not found

```bash
# Instalar extensión PostgreSQL
sudo apt install postgresql-contrib

# Habilitar en la base de datos
psql -h localhost -p 5433 -U roraima roraima_app_development
CREATE EXTENSION pg_trgm;
```

### Error: Couldn't find secret key base

```bash
# Generar secret key
rails secret

# Agregar a config/credentials.yml.enc
EDITOR=vim rails credentials:edit
```

### Tailwind CSS no recompila

```bash
# Verificar que bin/dev está corriendo
# O ejecutar manualmente:
rails tailwindcss:watch
```

### Sidekiq no procesa jobs

```bash
# Verificar que Redis está corriendo
redis-cli ping
# Debe responder: PONG

# Iniciar Redis
sudo systemctl start redis-server

# Iniciar Sidekiq
bundle exec sidekiq
```

## Próximos Pasos

- [Setup con Docker](./docker.md) - Alternativa usando contenedores
- [Deployment a Producción](./production.md)
- [Arquitectura del Sistema](../architecture/overview.md)
- [Guía de Carga Masiva](../bulk/carga-masiva.md)

## Variables de Entorno Opcionales

Crear archivo `.env` en la raíz:

```bash
# Base de datos
DATABASE_PASSWORD=roraima_dev_password

# Sidekiq (producción)
SIDEKIQ_USERNAME=admin
SIDEKIQ_PASSWORD=tu_password_seguro

# Rails
RAILS_ENV=development
RAILS_MAX_THREADS=5
```

**IMPORTANTE:** No commitear `.env` al repositorio. Ya está en `.gitignore`.
