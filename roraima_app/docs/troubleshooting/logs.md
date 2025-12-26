# Logs y Monitoreo

**Última actualización:** Diciembre 2025

Esta guía cubre cómo interpretar logs, monitorear la aplicación y debugging en Roraima Delivery.

## Ubicación de Logs

### Desarrollo

```bash
# Rails logs
log/development.log

# Sidekiq logs (si se ejecuta manualmente)
log/sidekiq.log

# Test logs
log/test.log
```

### Producción

```bash
# Rails logs
log/production.log

# Nginx logs (VPS)
/var/log/nginx/access.log
/var/log/nginx/error.log

# System logs (systemd services)
sudo journalctl -u puma
sudo journalctl -u sidekiq
```

---

## Leer Logs de Rails

### Formato de Log Entry

```
[timestamp] LEVEL -- : [info] mensaje
```

**Ejemplo:**

```
I, [2025-12-26T10:30:45.123456 #12345]  INFO -- : Started GET "/admin/packages" for 127.0.0.1 at 2025-12-26 10:30:45 -0300
Processing by Admin::PackagesController#index as HTML
  User Load (0.5ms)  SELECT "users".* FROM "users" WHERE "users"."id" = $1 LIMIT $2  [["id", 1], ["LIMIT", 1]]
  Package Load (1.2ms)  SELECT "packages".* FROM "packages" LIMIT $1 OFFSET $2  [["LIMIT", 10], ["OFFSET", 0]]
  Rendered admin/packages/index.html.erb within layouts/application (Duration: 15.3ms | Allocations: 5432)
Completed 200 OK in 25ms (Views: 18.2ms | ActiveRecord: 1.7ms | Allocations: 8765)
```

### Niveles de Log

| Nivel | Descripción | Uso |
|-------|-------------|-----|
| `DEBUG` | Información detallada | Debugging profundo |
| `INFO` | Información general | Requests, queries |
| `WARN` | Advertencias | Deprecated methods, N+1 queries |
| `ERROR` | Errores recuperables | Excepciones manejadas |
| `FATAL` | Errores críticos | Crash de app |

**Configurar nivel:**

```ruby
# config/environments/development.rb
config.log_level = :debug  # Muestra todo

# config/environments/production.rb
config.log_level = :info  # Solo info y superior
```

---

## Comandos Útiles

### Tail Logs en Tiempo Real

```bash
# Seguir log de desarrollo
tail -f log/development.log

# Seguir solo errores
tail -f log/production.log | grep ERROR

# Seguir con color (grc - generic colouriser)
grc tail -f log/development.log
```

### Buscar en Logs

```bash
# Buscar errores
grep "ERROR" log/development.log

# Buscar por clase/modelo
grep "Package" log/development.log

# Buscar con contexto (3 líneas antes/después)
grep -C 3 "BulkPackageUploadService" log/development.log

# Contar ocurrencias
grep -c "ActiveRecord" log/development.log
```

### Filtrar por Fecha/Hora

```bash
# Logs de hoy
grep "2025-12-26" log/development.log

# Logs de una hora específica
grep "2025-12-26T10:" log/development.log

# Últimas 100 líneas
tail -n 100 log/development.log

# Primeras 50 líneas
head -n 50 log/development.log
```

### Limpiar Logs

```bash
# Limpiar logs de desarrollo (cuidado!)
> log/development.log

# O usando rake task
rails log:clear

# Rotar logs (crear backup)
mv log/development.log log/development.log.old
touch log/development.log
```

---

## Interpretar Logs Comunes

### Request HTTP

```
Started GET "/admin/packages" for 127.0.0.1 at 2025-12-26 10:30:45 -0300
```

**Info:**
- Método: `GET`
- Ruta: `/admin/packages`
- IP: `127.0.0.1` (localhost)
- Timestamp: `2025-12-26 10:30:45`

---

### Processing de Controlador

```
Processing by Admin::PackagesController#index as HTML
  Parameters: {"status"=>"in_transit", "date_from"=>"2025-12-01"}
```

**Info:**
- Controlador: `Admin::PackagesController`
- Acción: `index`
- Formato: `HTML` (puede ser JSON, PDF, etc.)
- Parámetros: Filtros aplicados

---

### Queries de ActiveRecord

```
Package Load (1.2ms)  SELECT "packages".* FROM "packages" WHERE "packages"."status" = $1 LIMIT $2  [["status", 2], ["LIMIT", 10]]
```

**Info:**
- Modelo: `Package`
- Acción: `Load` (SELECT)
- Tiempo: `1.2ms`
- Query: SQL completo
- Bindings: `status = 2` (in_transit), `LIMIT = 10`

**Red Flags:**

```
# ⚠️ N+1 Query
Package Load (0.5ms)  SELECT ...  # 1 query
Commune Load (0.3ms)  SELECT ... WHERE id = 1  # +1 query por paquete
Commune Load (0.3ms)  SELECT ... WHERE id = 5  # +1 query por paquete
Commune Load (0.3ms)  SELECT ... WHERE id = 12  # +1 query por paquete
# ... (100 queries más)
```

**Solución:** Usar `includes(:commune)`

---

### Render de Vistas

```
Rendered admin/packages/index.html.erb within layouts/application (Duration: 15.3ms | Allocations: 5432)
```

**Info:**
- Template: `admin/packages/index.html.erb`
- Layout: `layouts/application`
- Tiempo: `15.3ms`
- Allocations: `5432` (objetos creados en memoria)

**Red Flags:**

```
# ⚠️ Vista muy lenta
Rendered admin/packages/index.html.erb (Duration: 2500.0ms)
```

**Posibles causas:**
- Queries en la vista (hacer en controlador)
- Loops anidados
- Rendering de muchos partials

---

### Completion

```
Completed 200 OK in 25ms (Views: 18.2ms | ActiveRecord: 1.7ms | Allocations: 8765)
```

**Info:**
- Status: `200 OK` (éxito)
- Tiempo total: `25ms`
- Tiempo en vistas: `18.2ms`
- Tiempo en DB: `1.7ms`
- Allocations: `8765` objetos

**Otros status comunes:**

| Status | Significado |
|--------|-------------|
| `200 OK` | Éxito |
| `302 Found` | Redirect |
| `401 Unauthorized` | No autenticado |
| `403 Forbidden` | No autorizado (Pundit) |
| `404 Not Found` | Recurso no existe |
| `422 Unprocessable Entity` | Validación falló |
| `500 Internal Server Error` | Error del servidor |

---

## Logs de Sidekiq

### Job Enqueued

```
2025-12-26T10:30:45.123Z pid=12345 tid=abcd INFO: Enqueued BulkPackageUploadJob (Job ID: xyz123) to Sidekiq(default)
```

**Info:**
- Job: `BulkPackageUploadJob`
- Job ID: `xyz123`
- Queue: `default`

---

### Job Processing

```
2025-12-26T10:30:46.456Z pid=12345 tid=abcd BulkPackageUploadJob JID-xyz123 INFO: start
2025-12-26T10:30:48.789Z pid=12345 tid=abcd BulkPackageUploadJob JID-xyz123 INFO: done: 2.333 sec
```

**Info:**
- Inicio: `10:30:46`
- Fin: `10:30:48`
- Duración: `2.333 seg`

---

### Job Failed

```
2025-12-26T10:30:50.123Z pid=12345 tid=abcd BulkPackageUploadJob JID-xyz123 ERROR: Job failed
ActiveRecord::RecordInvalid: Validation failed: Commune can't be blank
```

**Info:**
- Error: `ActiveRecord::RecordInvalid`
- Mensaje: `Validation failed: Commune can't be blank`
- El job se reintentará automáticamente (hasta 25 veces)

---

## Logs de Nginx (Producción)

### Access Log

```
127.0.0.1 - - [26/Dec/2025:10:30:45 -0300] "GET /admin/packages HTTP/1.1" 200 5432 "https://roraima.cl/admin" "Mozilla/5.0 ..."
```

**Info:**
- IP: `127.0.0.1`
- Timestamp: `26/Dec/2025:10:30:45`
- Request: `GET /admin/packages HTTP/1.1`
- Status: `200`
- Bytes: `5432`
- Referer: `https://roraima.cl/admin`
- User-Agent: Navegador

---

### Error Log

```
2025/12/26 10:30:45 [error] 12345#0: *123 connect() failed (111: Connection refused) while connecting to upstream
```

**Info:**
- Error: `Connection refused`
- Upstream: Backend Rails (Puma) no responde

**Soluciones:**
- Verificar que Puma está corriendo
- Revisar config de socket en Nginx

---

## Monitoreo en Producción

### Heroku Logs

```bash
# Tail logs
heroku logs --tail

# Logs de dynos específicos
heroku logs --tail --dyno web
heroku logs --tail --dyno worker

# Filtrar por palabra
heroku logs --tail | grep ERROR

# Últimas 500 líneas
heroku logs -n 500
```

---

### Systemd Logs (VPS)

```bash
# Puma logs
sudo journalctl -u puma -f

# Sidekiq logs
sudo journalctl -u sidekiq -f

# Últimas 100 líneas
sudo journalctl -u puma -n 100

# Logs desde hace 1 hora
sudo journalctl -u puma --since "1 hour ago"

# Logs de hoy
sudo journalctl -u puma --since today
```

---

## Performance Monitoring

### Identificar Queries Lentos

Agregar a `config/environments/development.rb`:

```ruby
config.active_record.verbose_query_logs = true

# Log queries > 100ms
ActiveSupport::Notifications.subscribe("sql.active_record") do |name, start, finish, id, payload|
  duration = (finish - start) * 1000
  if duration > 100
    Rails.logger.warn "SLOW QUERY (#{duration.round(2)}ms): #{payload[:sql]}"
  end
end
```

**Output:**

```
SLOW QUERY (234.56ms): SELECT "packages".* FROM "packages" WHERE ...
```

---

### Bullet (Detectar N+1)

```ruby
# Gemfile
group :development do
  gem 'bullet'
end

# config/environments/development.rb
config.after_initialize do
  Bullet.enable = true
  Bullet.alert = true  # Alert en browser
  Bullet.bullet_logger = true  # Log en bullet.log
  Bullet.console = true  # Output en consola
  Bullet.rails_logger = true  # Log en development.log
end
```

**Output:**

```
USE eager loading detected
  Package => [:commune]
  Add to your query: .includes([:commune])
```

---

### Rack Mini Profiler

```ruby
# Gemfile
group :development do
  gem 'rack-mini-profiler'
end
```

**Features:**
- Badge en esquina superior izquierda con tiempo de request
- Click para ver breakdown de queries, views, allocations
- Flamegraphs de CPU

---

## Custom Logging

### Logger en Modelos/Servicios

```ruby
class BulkPackageUploadService
  def process!
    Rails.logger.info "Iniciando procesamiento de #{@bulk_upload.id}"

    packages.each_with_index do |pkg, index|
      Rails.logger.debug "Procesando fila #{index + 1}: #{pkg.tracking_code}"
    end

    Rails.logger.info "Completado: #{success_count} paquetes creados"
  rescue => e
    Rails.logger.error "Error en bulk upload: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end
end
```

**Output:**

```
INFO -- : Iniciando procesamiento de 123
DEBUG -- : Procesando fila 1: PKG-12345...
DEBUG -- : Procesando fila 2: PKG-67890...
INFO -- : Completado: 50 paquetes creados
```

---

### Tagged Logging

```ruby
# En controlador
def create
  Rails.logger.tagged("BulkUpload", current_user.email) do
    Rails.logger.info "Usuario subió archivo: #{params[:file].original_filename}"
    # ...
  end
end
```

**Output:**

```
[BulkUpload] [admin@roraima.cl] Usuario subió archivo: paquetes.csv
```

---

## Log Rotation

### Logrotate (Linux)

Crear `/etc/logrotate.d/rails-app`:

```
/home/deploy/roraima_app/log/*.log {
  daily
  missingok
  rotate 7
  compress
  delaycompress
  notifempty
  copytruncate
  sharedscripts
  postrotate
    systemctl reload puma
  endscript
}
```

**Configuración:**
- `daily` - Rotar diariamente
- `rotate 7` - Mantener 7 días de logs
- `compress` - Comprimir logs antiguos
- `copytruncate` - No interrumpir escritura

**Forzar rotación manual:**

```bash
sudo logrotate -f /etc/logrotate.d/rails-app
```

---

## Debugging Avanzado

### Habilitar SQL Logging en Console

```ruby
rails console

# Habilitar logging de queries
ActiveRecord::Base.logger = Logger.new(STDOUT)

# Ahora todos los queries se muestran
Package.first
# SELECT "packages".* FROM "packages" ORDER BY "packages"."id" ASC LIMIT $1  [["LIMIT", 1]]
```

---

### Ver Request/Response Completo

```ruby
# En controlador
def index
  Rails.logger.debug "Headers: #{request.headers.inspect}"
  Rails.logger.debug "Params: #{params.inspect}"
  Rails.logger.debug "Session: #{session.inspect}"

  # ...

  Rails.logger.debug "Response: #{response.body.first(500)}"
end
```

---

### Benchmark Code

```ruby
require 'benchmark'

time = Benchmark.measure do
  Package.includes(:commune).limit(1000).to_a
end

Rails.logger.info "Query took: #{time.real} seconds"
```

---

## Herramientas Externas

### New Relic

```ruby
# Gemfile
gem 'newrelic_rpm'

# config/newrelic.yml
production:
  license_key: <%= ENV['NEW_RELIC_LICENSE_KEY'] %>
  app_name: Roraima Delivery

# Heroku
heroku addons:create newrelic:wayne
```

---

### Sentry (Error Tracking)

```ruby
# Gemfile
gem 'sentry-ruby'
gem 'sentry-rails'

# config/initializers/sentry.rb
Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN']
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.traces_sample_rate = 0.1  # 10% de requests
end
```

---

### Scout APM

```ruby
# Gemfile
gem 'scout_apm'

# config/scout_apm.yml
production:
  key: <%= ENV['SCOUT_KEY'] %>
  name: Roraima Delivery
  monitor: true
```

---

## Checklist de Debugging

Cuando hay un problema en producción:

- [ ] Revisar logs de Rails (`log/production.log`)
- [ ] Revisar logs de Nginx (`/var/log/nginx/error.log`)
- [ ] Revisar logs de systemd (`journalctl -u puma`)
- [ ] Revisar Sidekiq Web UI (`/sidekiq`)
- [ ] Verificar métricas de servidor (CPU, RAM, Disk)
- [ ] Revisar errores en Sentry/New Relic
- [ ] Reproducir en staging/desarrollo
- [ ] Ejecutar queries en console
- [ ] Agregar logging adicional si es necesario
- [ ] Rollback si es crítico

---

## Referencias

- [Errores Comunes](./errores-comunes.md)
- [Setup Producción](../setup/production.md)
- [Rails Guides - Debugging](https://guides.rubyonrails.org/debugging_rails_applications.html)
- [Sidekiq Logging](https://github.com/mperham/sidekiq/wiki/Logging)
