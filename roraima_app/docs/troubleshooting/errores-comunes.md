# Errores Comunes y Soluciones

**Última actualización:** Diciembre 2025

Esta guía cubre los errores más frecuentes en Roraima Delivery y sus soluciones.

## Errores de Base de Datos

### Error: `PG::ConnectionBad - could not connect to server`

**Síntomas:**
```
PG::ConnectionBad: could not connect to server: Connection refused
Is the server running on host "localhost" (127.0.0.1) and accepting
TCP/IP connections on port 5433?
```

**Causas:**
1. PostgreSQL no está corriendo
2. PostgreSQL está en puerto incorrecto
3. Credenciales incorrectas

**Soluciones:**

```bash
# 1. Verificar que PostgreSQL está corriendo
sudo systemctl status postgresql
# Si no está corriendo:
sudo systemctl start postgresql

# 2. Verificar puerto en postgresql.conf
sudo cat /etc/postgresql/*/main/postgresql.conf | grep port
# Debe mostrar: port = 5433

# 3. Verificar config/database.yml
cat config/database.yml
# port: 5433
# username: roraima
# password: ...

# 4. Probar conexión manual
psql -h localhost -p 5433 -U roraima roraima_app_development
```

---

### Error: `PG::UndefinedTable - relation "packages" does not exist`

**Síntomas:**
```
ActiveRecord::StatementInvalid: PG::UndefinedTable: ERROR:  relation "packages" does not exist
```

**Causa:** Migraciones no ejecutadas

**Solución:**

```bash
# Ejecutar migraciones
rails db:migrate

# Verificar estado
rails db:migrate:status

# Si la BD no existe, crearla primero
rails db:create
rails db:migrate
```

---

### Error: `PG::UniqueViolation - duplicate key value violates unique constraint`

**Síntomas:**
```
ActiveRecord::RecordNotUnique: PG::UniqueViolation: ERROR:  duplicate key value violates unique constraint "index_packages_on_tracking_code"
```

**Causa:** Intento de crear paquete con `tracking_code` duplicado

**Solución:**

El sistema genera tracking codes únicos automáticamente. Si ocurre este error:

```ruby
# Verificar si el código ya existe
Package.exists?(tracking_code: "PKG-123...")

# Generar nuevo tracking code
loop do
  tracking_code = "PKG-#{SecureRandom.random_number(10**14).to_s.rjust(14, '0')}"
  break unless Package.exists?(tracking_code: tracking_code)
end
```

**Prevención:** No crear paquetes manualmente sin generar tracking code.

---

## Errores de Autenticación

### Error: `Devise - You are already signed in`

**Síntomas:** Usuario intenta acceder a `/users/sign_in` estando autenticado

**Causa:** Devise redirige usuarios autenticados

**Solución:**

```ruby
# En ApplicationController
def after_sign_in_path_for(resource)
  # Redirigir según rol
  if resource.admin?
    admin_root_path
  elsif resource.driver?
    drivers_root_path
  else
    customers_root_path
  end
end
```

---

### Error: `Pundit::NotAuthorizedError`

**Síntomas:**
```
Pundit::NotAuthorizedError: not allowed to create? this Package
```

**Causa:** Usuario sin permisos para la acción

**Solución:**

Verificar política en `app/policies/package_policy.rb`:

```ruby
def create?
  # Drivers NO pueden crear paquetes
  user.admin? || user.customer?
end
```

**Debugging:**

```ruby
# En rails console
user = User.find(123)
package = Package.new
PackagePolicy.new(user, package).create?
# => true/false
```

---

## Errores de Carga Masiva

### Error: `TELÉFONO - formato inválido`

**Síntomas:** Fila rechazada con error de teléfono

**Causas Comunes:**
- Teléfono no es móvil (empieza con 2, no 9)
- Muy corto o muy largo
- Caracteres no numéricos

**Solución:**

```csv
# ❌ INCORRECTO
"212345678"  # Teléfono fijo (empieza con 2)
"9123"       # Muy corto
"+56 2 1234 5678"  # Fijo, no móvil

# ✅ CORRECTO
"912345678"
"+56912345678"
"9 1234 5678"  # Se normaliza automáticamente
```

**Formato Final:** `+569XXXXXXXX` (12 caracteres)

---

### Error: `COMUNA - no existe en el sistema`

**Síntomas:** Fila rechazada porque comuna no se encuentra

**Causas Comunes:**
- Typo en nombre (ej: "Providecia" en vez de "Providencia")
- Comuna fuera de Región Metropolitana
- Caracteres especiales mal codificados

**Solución:**

```csv
# ✅ Usar nombres correctos
"Santiago"  # No "Santiago Centro" (se normaliza)
"Providencia"
"Las Condes"
"Maipú"  # Con acento
"Ñuñoa"  # Con Ñ

# ✅ Aliases soportados
"Santiago Centro" → "Santiago"
"Maipu" → "Maipú"
"Nunoa" → "Ñuñoa"
"Stgo" → "Santiago"
```

**Ver lista de comunas válidas:**

```bash
rails runner "
  region = Region.find_by(name: 'Región Metropolitana')
  Commune.where(region: region).order(:name).pluck(:name).each { |c| puts c }
"
```

---

### Error: `EMPRESA - email no existe` (Admin)

**Síntomas:** Admin intenta cargar paquetes para cliente inexistente

**Causa:** Email del customer no está registrado

**Solución:**

1. Crear customer primero en `/admin/users/new`
2. Verificar email exacto (case-sensitive en algunos casos)
3. Verificar que el usuario tenga `role: customer`

```ruby
# En rails console
User.customer.find_by(email: "cliente@empresa.com")
# => nil (no existe)

# Crear customer
User.create!(
  email: "cliente@empresa.com",
  password: "password123",
  role: :customer,
  active: true
)
```

---

## Errores de Sidekiq

### Error: Sidekiq no procesa jobs

**Síntomas:** BulkUploadJob queda en `pending`, nunca completa

**Causas:**
1. Sidekiq no está corriendo
2. Redis no está corriendo
3. Job falló y está en retry

**Soluciones:**

```bash
# 1. Verificar Sidekiq
ps aux | grep sidekiq
# Si no está corriendo:
bundle exec sidekiq

# 2. Verificar Redis
redis-cli ping
# Debe responder: PONG
# Si no:
sudo systemctl start redis-server

# 3. Ver jobs fallidos en Sidekiq Web UI
# http://localhost:3000/sidekiq
# (solo admins)

# 4. Reintentar job manualmente
rails console
job_id = "abc123..."
Sidekiq::RetrySet.new.find { |j| j.jid == job_id }&.retry
```

---

### Error: `Redis::CannotConnectError`

**Síntomas:**
```
Redis::CannotConnectError: Error connecting to Redis on localhost:6379 (Errno::ECONNREFUSED)
```

**Causa:** Redis no está corriendo

**Solución:**

```bash
# Ubuntu/Debian
sudo systemctl start redis-server
sudo systemctl enable redis-server

# macOS
brew services start redis

# Verificar
redis-cli ping
# Debe responder: PONG
```

---

## Errores de Assets/Tailwind

### Error: CSS no se aplica

**Síntomas:** Cambios en Tailwind no se reflejan en la UI

**Causa:** Tailwind no está recompilando

**Solución:**

```bash
# Opción 1: Usar bin/dev (recomendado)
bin/dev

# Opción 2: Recompilar manualmente
rails tailwindcss:build

# Opción 3: Watch mode (desarrollo)
rails tailwindcss:watch
```

---

### Error: `Sprockets::FileNotFound - couldn't find file 'application'`

**Síntomas:**
```
Sprockets::FileNotFound: couldn't find file 'application' with type 'text/css'
```

**Causa:** Assets no precompilados (producción)

**Solución:**

```bash
# Precompilar assets
RAILS_ENV=production rails assets:precompile

# Limpiar cache si persiste
RAILS_ENV=production rails assets:clobber
RAILS_ENV=production rails assets:precompile
```

---

## Errores de Extensiones PostgreSQL

### Error: `PG::UndefinedFunction - function similarity() does not exist`

**Síntomas:**
```
ActiveRecord::StatementInvalid: PG::UndefinedFunction: ERROR:  function similarity(character varying, unknown) does not exist
```

**Causa:** Extensión `pg_trgm` no instalada

**Solución:**

```bash
# Conectar a PostgreSQL
psql -h localhost -p 5433 -U roraima roraima_app_development

# Crear extensión
CREATE EXTENSION IF NOT EXISTS pg_trgm;

# Verificar
\dx
# Debe listar pg_trgm

# Salir
\q
```

---

## Errores de Validación

### Error: `Validation failed: Phone format is invalid`

**Síntomas:** No se puede crear/actualizar paquete

**Causa:** Teléfono no cumple formato `+569XXXXXXXX`

**Solución:**

```ruby
# Normalizar teléfono antes de guardar
package.phone = normalize_phone("912345678")
# => "+56912345678"

# O usar before_validation callback
class Package < ApplicationRecord
  before_validation :normalize_phone_format

  private

  def normalize_phone_format
    self.phone = BulkPackageUploadService.new(nil).send(:normalize_phone, phone)
  end
end
```

---

### Error: `Validation failed: Tracking code has already been taken`

**Síntomas:** Tracking code duplicado al crear paquete

**Causa:** Código generado aleatoriamente ya existe (muy raro)

**Solución:**

El modelo `Package` tiene `before_validation :generate_tracking_code`:

```ruby
def generate_tracking_code
  loop do
    self.tracking_code = "PKG-#{SecureRandom.random_number(10**14).to_s.rjust(14, '0')}"
    break unless Package.exists?(tracking_code: tracking_code)
  end
end
```

Si persiste, verificar que el callback está definido.

---

## Errores de Permisos

### Error: Permission denied al ejecutar rails commands

**Síntomas:**
```
bash: /home/deploy/app/bin/rails: Permission denied
```

**Causa:** Archivos en `bin/` sin permisos de ejecución

**Solución:**

```bash
chmod +x bin/*
git update-index --chmod=+x bin/*
```

---

### Error: ActiveStorage - `TypeError: can't dump File`

**Síntomas:**
```
TypeError: can't dump File
```

**Causa:** Intentando serializar objeto File directamente

**Solución:**

```ruby
# ❌ INCORRECTO
bulk_upload.file = params[:file]  # File object

# ✅ CORRECTO
bulk_upload.file.attach(params[:file])
```

---

## Errores de Estado de Paquetes

### Error: `Transición no permitida`

**Síntomas:** PackageStatusService rechaza cambio de estado

**Causa:** Transición no está en `ALLOWED_TRANSITIONS`

**Solución:**

Verificar flujo válido en `app/models/package.rb`:

```ruby
ALLOWED_TRANSITIONS = {
  pending_pickup: [:in_warehouse, :cancelled, :picked_up],
  in_warehouse: [:in_transit, :picked_up, :return, :cancelled],
  in_transit: [:delivered, :rescheduled, :return],
  # ...
}
```

Si necesitas forzar (solo admin):

```ruby
service = PackageStatusService.new
service.change_status(
  package,
  :in_transit,
  admin,
  admin_override: true,
  reason: "Corrección manual"
)
```

---

## Errores de Performance

### Error: Queries muy lentos (N+1)

**Síntomas:** Página tarda mucho en cargar

**Causa:** Queries N+1 (no usar eager loading)

**Solución:**

```ruby
# ❌ N+1 Query
@packages = Package.all
@packages.each do |pkg|
  puts pkg.commune.name  # Query adicional por cada paquete
end

# ✅ Eager Loading
@packages = Package.includes(:commune)
@packages.each do |pkg|
  puts pkg.commune.name  # Sin query adicional
end
```

**Detectar N+1:**

```ruby
# Gemfile (development)
gem 'bullet'

# config/environments/development.rb
config.after_initialize do
  Bullet.enable = true
  Bullet.alert = true
  Bullet.bullet_logger = true
  Bullet.console = true
  Bullet.rails_logger = true
end
```

---

## Debugging General

### Revisar Logs

```bash
# Development logs
tail -f log/development.log

# Production logs
tail -f log/production.log

# Filtrar por errores
grep "ERROR" log/development.log

# Filtrar por modelo específico
grep "Package" log/development.log
```

### Rails Console

```ruby
rails console

# Verificar datos
Package.count
User.admin.count
Driver.count

# Probar servicio
service = BulkPackageUploadService.new(bulk_upload)
service.process!

# Rollback automático (sandbox)
rails console --sandbox
Package.create!(...)  # Se revierte al salir
```

### Byebug/Pry

```ruby
# En cualquier parte del código
require 'byebug'
byebug  # Breakpoint

# En consola
next  # Siguiente línea
step  # Entrar en método
continue  # Continuar ejecución
@variable  # Inspeccionar variable
```

---

## Recursos Útiles

- [Logs del Sistema](./logs.md)
- [Setup Local](../setup/local.md)
- [Validaciones de Carga Masiva](../bulk/validaciones.md)
- [Sistema de Estados](../operations/estados.md)

---

## Reportar Bugs

Si encuentras un error no documentado:

1. Recopilar información:
   - Mensaje de error completo
   - Stack trace
   - Logs relevantes
   - Pasos para reproducir

2. Buscar en issues existentes:
   - GitHub Issues
   - Documentación

3. Crear issue con formato:
   ```markdown
   ## Error

   Descripción breve

   ## Pasos para Reproducir

   1. Paso 1
   2. Paso 2
   3. Error ocurre

   ## Stack Trace

   ```
   Error completo aquí
   ```

   ## Entorno

   - Ruby: 3.2.2
   - Rails: 7.1.5
   - PostgreSQL: 12
   - OS: Ubuntu 22.04
   ```
