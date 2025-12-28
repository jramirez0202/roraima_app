# 🐳 Gu

ía de Docker - Roraima Delivery App

Esta guía explica cómo usar Docker para desarrollo local de la aplicación Roraima Delivery. Está diseñada para alguien que dockeriza **por primera vez** y quiere entender qué está haciendo.

---

## 📋 Tabla de Contenidos

1. [¿Qué es Docker?](#-qué-es-docker)
2. [Requisitos Previos](#-requisitos-previos)
3. [Configuración Inicial](#-configuración-inicial)
4. [Comandos Básicos](#-comandos-básicos)
5. [Arquitectura de Servicios](#-arquitectura-de-servicios)
6. [Troubleshooting](#-troubleshooting)
7. [Conceptos Docker Explicados](#-conceptos-docker-explicados)
8. [Dockerfile Explicado Línea por Línea](#-dockerfile-explicado-línea-por-línea)

---

## 🤔 ¿Qué es Docker?

**Docker** es como un "empaquetador" de aplicaciones. Imagina que tu aplicación Rails es una casa que necesita:

- **Cimientos** (sistema operativo Linux)
- **Servicios públicos** (PostgreSQL para base de datos, Redis para colas)
- **Instalaciones** (Ruby, gemas, dependencias)

Sin Docker, cada desarrollador debe configurar todo esto manualmente en su máquina. Con Docker, empaquetas TODO en **contenedores** que funcionan igual en cualquier computadora.

### Analogía del Contenedor de Barco

Docker toma su nombre de los contenedores de carga de barcos:

```
┌─────────────────────────────────────────┐
│  TU COMPUTADORA (Puerto marítimo)       │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │   Docker Engine (Barco)          │  │
│  │                                  │  │
│  │  ┌──────┐  ┌──────┐  ┌──────┐   │  │
│  │  │ Web  │  │ Sidekiq│  │ DB  │   │  │
│  │  │Rails │  │Jobs  │  │Postgres│   │  │
│  │  └──────┘  └──────┘  └──────┘   │  │
│  │                                  │  │
│  │  Contenedores aislados           │  │
│  └──────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

Cada contenedor:
- Está **aislado** (no interfiere con otros)
- Es **portátil** (funciona igual en cualquier máquina)
- Tiene **todo lo que necesita** para ejecutar una aplicación

### Componentes Clave

#### 1. **Dockerfile**
Receta para construir la imagen de tu app Rails.

```dockerfile
# Ejemplo simplificado
FROM ruby:3.2.2          # Usar imagen base de Ruby
WORKDIR /rails           # Crear carpeta /rails
COPY Gemfile* ./         # Copiar Gemfile
RUN bundle install       # Instalar gemas
COPY . .                 # Copiar código
CMD ["rails", "server"]  # Comando por defecto
```

#### 2. **docker-compose.yml**
Orquestador que conecta múltiples servicios (Rails + Postgres + Redis + Sidekiq).

```yaml
services:
  postgres:  # Base de datos
  redis:     # Cache y colas
  web:       # Rails app
  sidekiq:   # Jobs background
```

#### 3. **Imagen**
Plantilla inmutable de tu app (como un ISO de sistema operativo).

#### 4. **Contenedor**
Instancia en ejecución de una imagen (como una máquina virtual corriendo).

#### 5. **Volumen**
Almacenamiento persistente (datos de DB, archivos subidos).

#### 6. **Network**
Red interna para que los contenedores se comuniquen.

### Ventajas de Docker

✅ **No necesitas instalar** PostgreSQL, Redis, ni configurar versiones de Ruby
✅ **Mismo entorno** para todos los desarrolladores
✅ **Fácil de limpiar**: Un comando elimina todo sin dejar archivos basura
✅ **Preparado para producción**: El mismo Dockerfile se usa en desarrollo y producción

---

## ✅ Requisitos Previos

### 1. Instalar Docker Desktop

#### **macOS / Windows:**

1. Descarga Docker Desktop: https://www.docker.com/products/docker-desktop/
2. Ejecuta el instalador
3. Inicia Docker Desktop y espera a que el ícono de ballena esté quieto
4. Verifica instalación:

```bash
docker --version
# Docker version 24.0.0 o superior

docker compose version
# Docker Compose version v2.20.0 o superior
```

#### **Linux (Ubuntu/Debian):**

```bash
# Instalar Docker Engine
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Agregar tu usuario al grupo docker (evita usar sudo)
sudo usermod -aG docker $USER
newgrp docker

# Verificar
docker --version
docker compose version
```

### 2. Recursos Recomendados

Docker Desktop → **Preferences** → **Resources**:

- **CPU**: Mínimo 2 cores (recomendado 4)
- **Memoria**: Mínimo 4 GB (recomendado 6-8 GB)
- **Disco**: Mínimo 20 GB libres

**¿Por qué tanto?**
- Ruby + Rails + Postgres + Redis + Sidekiq = ~2 GB RAM en uso
- Build de imágenes necesita espacio temporal
- Volúmenes de datos (DB, archivos) crecen con el tiempo

---

## 🚀 Configuración Inicial

### Opción A: Script Automático (⭐ Recomendado)

```bash
# 1. Hacer ejecutable el script
chmod +x bin/docker-setup bin/docker-entrypoint

# 2. Ejecutar setup automático
./bin/docker-setup
```

**¿Qué hace el script?**

1. ✅ Verifica que Docker esté instalado y corriendo
2. ✅ Crea `.env.docker` desde `.env.docker.example`
3. ✅ Genera `SECRET_KEY_BASE` automáticamente
4. ✅ Construye las imágenes Docker (5-10 min)
5. ✅ Inicia PostgreSQL y Redis
6. ✅ Crea y migra la base de datos
7. ✅ Opcionalmente carga seeds (regiones, usuarios de prueba)
8. ✅ Inicia todos los servicios

**Tiempo estimado**: 5-10 minutos la primera vez.

Al finalizar, la aplicación estará corriendo en http://localhost:3000 🎉

### Opción B: Manual (Paso a Paso)

Si prefieres entender cada paso o el script automático falla:

#### 1. Copiar archivo de entorno

```bash
cp .env.docker.example .env.docker
```

#### 2. Generar SECRET_KEY_BASE

```bash
# Construir imagen de desarrollo
docker compose build web

# Generar secret (guarda el output)
docker compose run --rm web rails secret
# Output: una cadena larga de caracteres random

# Abrir .env.docker y reemplazar:
# SECRET_KEY_BASE=CHANGE_THIS_SECRET...
# Por:
# SECRET_KEY_BASE=<el secret que generaste>
```

#### 3. Construir todas las imágenes

```bash
docker compose build
```

**¿Qué está pasando?**
- Descarga imagen base de Ruby (100+ MB)
- Instala dependencias del sistema (Postgres client, libvips, etc.)
- Instala y compila gemas (bundle install)
- Precompila Bootsnap

**Tiempo**: 5-10 minutos la primera vez. Builds posteriores son más rápidos gracias al cache.

#### 4. Iniciar servicios base

```bash
# Iniciar postgres y redis
docker compose up -d postgres redis

# Esperar 10 segundos a que inicialicen
sleep 10
```

#### 5. Crear y migrar base de datos

```bash
# Crear base de datos
docker compose run --rm web rails db:create

# Ejecutar migraciones
docker compose run --rm web rails db:migrate

# (Opcional) Cargar seeds
docker compose run --rm web rails db:seed
```

**¿Qué hacen los seeds?**
- Crea 16 regiones de Chile + 345 comunas
- Crea usuarios de prueba:
  - `admin@roraima.cl` (admin)
  - `customer@roraima.cl` (cliente)
  - `driver@roraima.cl` (conductor)
- Crea zonas geográficas de ejemplo

Contraseña para todos: `password123`

#### 6. Iniciar todos los servicios

```bash
docker compose up -d
```

#### 7. Verificar que todo funciona

```bash
# Ver estado de servicios
docker compose ps

# Deberías ver:
# NAME               STATUS
# roraima_postgres   Up (healthy)
# roraima_redis      Up (healthy)
# roraima_web        Up
# roraima_sidekiq    Up
# roraima_tailwind   Up (si usaste --profile development)
```

#### 8. Acceder a la aplicación

Abre tu navegador en: **http://localhost:3000**

---

## 🎮 Comandos Básicos

### Iniciar/Detener Servicios

```bash
# Iniciar todos los servicios (en background)
docker compose up -d

# Iniciar solo algunos servicios
docker compose up -d web sidekiq

# Iniciar CON logs visibles (sin -d)
docker compose up
# Presiona Ctrl+C para detener

# Detener servicios (conserva volúmenes/datos)
docker compose down

# Detener Y ELIMINAR volúmenes (⚠️ BORRA BASE DE DATOS)
docker compose down -v
```

### Ver Logs

```bash
# Logs de todos los servicios
docker compose logs

# Logs en tiempo real (sigue actualizando)
docker compose logs -f

# Logs de un servicio específico
docker compose logs -f web
docker compose logs -f sidekiq
docker compose logs -f postgres

# Últimas 100 líneas
docker compose logs --tail=100 web

# Logs desde los últimos 5 minutos
docker compose logs --since 5m web
```

### Ejecutar Comandos Dentro de Contenedores

```bash
# Consola de Rails (⭐ MÁS USADO)
docker compose exec web rails console

# Bash en contenedor web
docker compose exec web bash
# Ahora estás "dentro" del contenedor
# ls -la  → ver archivos
# exit    → salir

# Ejecutar migraciones
docker compose exec web rails db:migrate

# Ejecutar tests
docker compose exec web rails test

# Rollback última migración
docker compose exec web rails db:rollback

# Ver rutas de Rails
docker compose exec web rails routes

# Limpiar assets compilados
docker compose exec web rails assets:clobber
```

**¿Cuál es la diferencia entre `exec` y `run`?**

- **`docker compose exec web <comando>`**: Ejecuta comando en contenedor YA CORRIENDO
- **`docker compose run web <comando>`**: Crea NUEVO contenedor temporal, ejecuta comando, lo elimina

Usa `exec` para comandos rápidos. Usa `run --rm` para comandos que necesitan estado limpio.

### Gestión de Base de Datos

```bash
# Crear base de datos (solo primera vez)
docker compose exec web rails db:create

# Ejecutar migraciones pendientes
docker compose exec web rails db:migrate

# Rollback última migración
docker compose exec web rails db:rollback

# Reset completo (⚠️ BORRA DATOS)
docker compose exec web rails db:reset

# Cargar seeds de nuevo
docker compose exec web rails db:seed

# Conectarse directamente a PostgreSQL
docker compose exec postgres psql -U postgres -d roraima_app_development

# Dentro de psql:
# \dt           → listar tablas
# \d packages   → ver estructura de tabla packages
# \dx           → listar extensiones (deberías ver pg_trgm)
# \q            → salir
```

### Rebuild de Imágenes

```bash
# Rebuild cuando cambies Gemfile o Dockerfile
docker compose build

# Rebuild SIN usar cache (útil si algo se rompe)
docker compose build --no-cache

# Rebuild solo un servicio
docker compose build web

# Rebuild y reiniciar
docker compose up -d --build
```

### Limpieza

```bash
# Eliminar contenedores detenidos de este proyecto
docker compose rm

# Eliminar contenedores + volúmenes (⚠️ BORRA DB)
docker compose down -v

# Ver uso de espacio de Docker
docker system df

# Eliminar imágenes no usadas
docker image prune

# Limpieza profunda (⚠️ AFECTA TODOS LOS PROYECTOS)
docker system prune -a --volumes
```

---

## 🏗️ Arquitectura de Servicios

Esta aplicación usa **5 servicios** que se comunican entre sí:

```
┌───────────────────────────────────────────┐
│           TU COMPUTADORA (Host)           │
│                                           │
│  ┌─────────────────────────────────────┐  │
│  │    Docker Network (roraima_network)  │  │
│  │                                     │  │
│  │   ┌────────┐         ┌────────┐    │  │
│  │   │  WEB   │────────▶│Postgres│    │  │
│  │   │(Rails) │         │  :5432 │    │  │
│  │   │ :3000  │         └────────┘    │  │
│  │   └────────┘              │        │  │
│  │       │                   │        │  │
│  │       ├──────────┐        │        │  │
│  │       │          │        │        │  │
│  │   ┌───▼────┐ ┌──▼─────┐  │        │  │
│  │   │Sidekiq │ │ Redis  │  │        │  │
│  │   │        │ │ :6379  │  │        │  │
│  │   └────────┘ └────────┘  │        │  │
│  │       │                  │        │  │
│  │   ┌───▼────────┐         │        │  │
│  │   │ Tailwind   │─────────┘        │  │
│  │   │   Watch    │                  │  │
│  │   └────────────┘                  │  │
│  └─────────────────────────────────────┘  │
│                                           │
│  Puertos mapeados:                        │
│  localhost:3000 → web:3000                │
│  localhost:5432 → postgres:5432           │
│  localhost:6379 → redis:6379              │
└───────────────────────────────────────────┘
```

### 1. PostgreSQL (`postgres`)

**Imagen**: `postgres:16-alpine`
**Puerto**: `5432` (host y contenedor)
**Datos**: Persistidos en volumen `postgres_data`

**¿Qué hace?**
- Base de datos principal de la aplicación
- Almacena usuarios, paquetes, zonas, comunas, etc.
- Extensión `pg_trgm` habilitada para búsquedas rápidas

**Healthcheck:**
```bash
pg_isready -U postgres
```

**Acceso directo:**
```bash
# Desde host (si tienes psql instalado)
psql -h localhost -p 5432 -U postgres -d roraima_app_development
# Contraseña: password

# Desde contenedor
docker compose exec postgres psql -U postgres -d roraima_app_development
```

**Comandos útiles en psql:**
```sql
-- Listar tablas
\dt

-- Ver estructura de tabla
\d packages

-- Ver extensiones instaladas
\dx

-- Contar paquetes
SELECT COUNT(*) FROM packages;

-- Ver últimos 10 paquetes
SELECT id, tracking_code, status FROM packages ORDER BY created_at DESC LIMIT 10;

-- Salir
\q
```

### 2. Redis (`redis`)

**Imagen**: `redis:7-alpine`
**Puerto**: `6379`
**Datos**: Persistidos en volumen `redis_data` (opcional)

**¿Qué hace?**
- Backend de colas para Sidekiq
- Cache de Rails (si se configura)
- Action Cable (WebSockets, si se usa)

**Healthcheck:**
```bash
redis-cli ping
# Responde: PONG
```

**Acceso directo:**
```bash
# Conectarse a Redis CLI
docker compose exec redis redis-cli

# Comandos útiles en redis-cli:
PING          # Responde PONG
KEYS *        # Ver todas las keys (⚠️ lento con millones de keys)
INFO          # Estadísticas del servidor
DBSIZE        # Número de keys en DB
FLUSHDB       # ⚠️ Borrar todo
QUIT          # Salir
```

**Colas de Sidekiq:**
```bash
# Ver colas de Sidekiq
docker compose exec redis redis-cli
> KEYS sidekiq:*
> LLEN sidekiq:queue:default
> LLEN sidekiq:queue:mailers
> LLEN sidekiq:queue:bulk_uploads
```

### 3. Web (`web`)

**Base**: Dockerfile stage `development`
**Puerto**: `3000`
**Código**: Montado desde host (hot-reload)

**¿Qué hace?**
- Servidor Rails con Puma
- Sirve la aplicación web
- Procesa requests HTTP
- Conecta con Postgres y Redis

**Volúmenes:**
- `.:/rails:cached` → Código fuente (hot-reload)
- `storage_data:/rails/storage` → Active Storage (persistente)
- `bundle_cache:/usr/local/bundle` → Gemas (acelera rebuilds)

**Healthcheck:**
```bash
curl -f http://localhost:3000/up
# Debe responder: 200 OK
```

**Hot-reload:**
```
Cambias archivo en tu editor → Se refleja inmediatamente en contenedor
```

No necesitas rebuild de Docker, solo refrescar el navegador.

### 4. Sidekiq (`sidekiq`)

**Base**: Misma imagen que `web`
**Sin puerto expuesto**
**Código**: Compartido con `web`

**¿Qué hace?**
- Procesa trabajos en background
- Queues: `default`, `mailers`, `bulk_uploads`
- Crítico para carga masiva de paquetes (CSV/Excel)

**Comando:**
```bash
bundle exec sidekiq -C config/sidekiq.yml
```

**Monitoreo:**
```bash
# Ver logs
docker compose logs -f sidekiq

# Ver Sidekiq Web UI (desde navegador, solo admin)
http://localhost:3000/sidekiq
```

**Configuración:**
```yaml
# config/sidekiq.yml
:concurrency: 5      # 5 workers simultáneos
:max_retries: 3      # Reintentar 3 veces si falla
:queues:
  - default          # Prioridad normal
  - mailers          # Emails
  - bulk_uploads     # Bulk CSV/Excel
```

### 5. Tailwind CSS (`tailwindcss`)

**Base**: Misma imagen que `web`
**Profile**: `development` (solo desarrollo)

**¿Qué hace?**
- Vigila cambios en archivos CSS/HTML/ERB
- Recompila Tailwind automáticamente
- Equivalente a `bin/rails tailwindcss:watch`

**Iniciar con Tailwind:**
```bash
# CON Tailwind watch
docker compose --profile development up -d

# SIN Tailwind watch (para producción)
docker compose up -d
```

**¿Cuándo se recompila?**
- Cambias un archivo `.html.erb` → recompila
- Agregas clase Tailwind nueva → recompila
- Cambias `app/assets/stylesheets/application.tailwind.css` → recompila

---

## 🐛 Troubleshooting

### Problema: "Couldn't find database"

**Síntoma:**
```
ActiveRecord::NoDatabaseError: FATAL: database "roraima_app_development" does not exist
```

**Solución:**
```bash
docker compose exec web rails db:create
docker compose exec web rails db:migrate
```

---

### Problema: "Could not connect to server: Connection refused"

**Síntoma:**
```
PG::ConnectionBad: could not connect to server: Connection refused
  Is the server running on host "postgres" and accepting connections on port 5432?
```

**Causas posibles:**
1. PostgreSQL no está corriendo
2. Healthcheck no pasó antes de iniciar Rails
3. Variables de entorno incorrectas

**Solución:**
```bash
# 1. Verificar estado de postgres
docker compose ps postgres

# Debería mostrar: Up (healthy)
# Si muestra: Up (unhealthy) o Exit, hay un problema

# 2. Ver logs de postgres
docker compose logs postgres

# 3. Reiniciar postgres
docker compose restart postgres

# 4. Esperar a que esté healthy
watch docker compose ps postgres
# Espera hasta que diga "Up (healthy)"

# 5. Reiniciar web
docker compose restart web
```

---

### Problema: "A server is already running"

**Síntoma:**
```
A server is already running. Check /rails/tmp/pids/server.pid.
```

**Causa:** El PID file quedó del último run (crash o detención abrupta).

**Solución:**
```bash
# Eliminar PID file
docker compose exec web rm /rails/tmp/pids/server.pid

# O reiniciar contenedor (también elimina el PID)
docker compose restart web
```

---

### Problema: "Bundler version mismatch"

**Síntoma:**
```
Your Gemfile.lock requires bundler version 2.4.17 but you are running 2.3.26
```

**Causa:** La imagen Docker tiene una versión diferente de Bundler.

**Solución:**
```bash
# Rebuild la imagen sin cache
docker compose build --no-cache web

# Reiniciar
docker compose up -d web
```

---

### Problema: Assets de Tailwind no se actualizan

**Síntoma:**
Cambias CSS pero no se refleja en el navegador.

**Causas:**
1. Tailwind watch no está corriendo
2. Cache del navegador

**Solución:**
```bash
# 1. Verificar que tailwindcss service esté corriendo
docker compose --profile development up -d

# 2. Ver logs de tailwindcss
docker compose logs -f tailwindcss

# Deberías ver: "Rebuilding..." cuando haces cambios

# 3. Forzar recompilación manual
docker compose exec web bin/rails tailwindcss:build

# 4. Limpiar cache del navegador
# Chrome/Firefox: Ctrl+Shift+R (hard refresh)
```

---

### Problema: Permisos denegados en storage/

**Síntoma:**
```
Errno::EACCES: Permission denied @ dir_s_mkdir - /rails/storage
```

**Causa:** El usuario dentro del contenedor (rails) no tiene permisos.

**Solución:**
```bash
# En host: Ajustar permisos
sudo chown -R $USER:$USER storage/ tmp/ log/

# O dar permisos amplios (menos seguro pero funciona)
chmod -R 777 storage/ tmp/ log/

# Reiniciar web
docker compose restart web
```

---

### Problema: Secret key base no configurado

**Síntoma:**
```
Missing secret_key_base for 'development' environment
```

**Solución:**
```bash
# 1. Generar nuevo secret
docker compose run --rm web rails secret

# 2. Copiar el output (cadena larga)

# 3. Abrir .env.docker y reemplazar:
# SECRET_KEY_BASE=CHANGE_THIS_SECRET...
# Por:
# SECRET_KEY_BASE=<el secret que copiaste>

# 4. Reiniciar
docker compose restart web
```

---

### Problema: Volúmenes llenos de datos viejos

**Síntoma:**
- Migraciones que no se aplican
- Datos incorrectos
- Errores de constraints

**Solución (⚠️ BORRA TODO):**
```bash
# 1. Detener servicios
docker compose down

# 2. Eliminar volúmenes
docker compose down -v

# 3. Reiniciar desde cero
./bin/docker-setup
```

---

### Problema: Docker se queda sin espacio

**Síntoma:**
```
Error: No space left on device
```

**Solución:**
```bash
# Ver uso de espacio
docker system df

# Limpiar imágenes no usadas
docker image prune -a

# Limpiar todo (⚠️ AFECTA TODOS LOS PROYECTOS)
docker system prune -a --volumes

# Si usas Docker Desktop:
# Preferences → Resources → Disk image size
# Aumentar el límite
```

---

### Problema: Redis no está disponible

**Síntoma:**
```
Error connecting to Redis
```

**Solución:**
```bash
# Verificar estado
docker compose ps redis

# Ver logs
docker compose logs redis

# Reiniciar
docker compose restart redis

# Probar conexión manualmente
docker compose exec redis redis-cli ping
# Debería responder: PONG
```

---

## 📚 Conceptos Docker Explicados

### 1. Multi-stage Build

**¿Qué es?**

Un Dockerfile con múltiples secciones (stages). Cada stage puede copiar archivos de stages anteriores.

**Ejemplo:**
```dockerfile
# Stage 1: Builder (compila gemas)
FROM ruby:3.2.2 AS builder
COPY Gemfile* ./
RUN bundle install

# Stage 2: Production (copia solo lo necesario)
FROM ruby:3.2.2 AS production
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY . .
```

**Beneficio:**
- Stage builder tiene herramientas de compilación (gcc, make, etc.)
- Stage production solo copia gemas compiladas
- Imagen final: ~500 MB vs ~1.5 GB sin multi-stage

### 2. Layer Caching

**¿Qué es?**

Cada instrucción (`RUN`, `COPY`, etc.) en Dockerfile crea una **capa** (layer). Docker cachea capas que no cambiaron.

**Ejemplo:**
```dockerfile
COPY Gemfile Gemfile.lock ./  # Layer 1
RUN bundle install            # Layer 2 (muy lenta)
COPY . .                      # Layer 3
```

**Escenarios:**

```
Cambio solo código (no Gemfile):
┌─────────────────────────────┐
│ Layer 1: COPY Gemfile  [✓]  │ ← Reutiliza cache
│ Layer 2: bundle install [✓] │ ← Reutiliza cache (¡no reinstala gemas!)
│ Layer 3: COPY código   [X]  │ ← Ejecuta (código cambió)
└─────────────────────────────┘
Build time: 10 segundos

Cambio Gemfile:
┌─────────────────────────────┐
│ Layer 1: COPY Gemfile  [X]  │ ← Ejecuta
│ Layer 2: bundle install [X] │ ← Ejecuta (instala gemas nuevas)
│ Layer 3: COPY código   [X]  │ ← Ejecuta
└─────────────────────────────┘
Build time: 5 minutos
```

**Por qué COPY Gemfile ANTES del código:**

Sin separación:
```dockerfile
COPY . .              # Código cambia → invalida cache
RUN bundle install    # Reinstala TODAS las gemas (lento)
```

Con separación:
```dockerfile
COPY Gemfile* ./      # Solo Gemfile → cache válido si no cambió
RUN bundle install    # Reutiliza cache
COPY . .              # Código cambia → solo esto se ejecuta
```

### 3. depends_on con condition

**Sin condition:**
```yaml
web:
  depends_on:
    - postgres
```

Orden de inicio: postgres → web

**Problema:** Postgres puede estar "arriba" pero aún no aceptar conexiones.

**Con condition:**
```yaml
web:
  depends_on:
    postgres:
      condition: service_healthy
```

**Flujo:**
1. Docker inicia postgres
2. Docker ejecuta healthcheck cada 10s: `pg_isready -U postgres`
3. Después de 5 intentos exitosos, marca postgres como "healthy"
4. Recién ahí inicia web

**Resultado:** Rails NO intenta conectar antes de que Postgres esté listo.

### 4. Bind Mounts vs Named Volumes

**Bind Mount:**
```yaml
volumes:
  - .:/rails:cached
```

- Sincroniza carpeta del host con contenedor
- Cambias archivo en VS Code → se refleja en /rails/ del contenedor
- Permite hot-reload (no rebuilds)

**Named Volume:**
```yaml
volumes:
  - postgres_data:/var/lib/postgresql/data
```

- Almacenamiento gestionado por Docker
- NO se sincroniza con host
- Persiste datos (sobrevive a `docker compose down`)
- No puedes ver archivos directamente en host

**Anonymous Volume:**
```yaml
volumes:
  - /rails/tmp
```

- Volumen temporal sin nombre
- Se borra cuando eliminas el contenedor
- Útil para excluir carpetas de sincronización

### 5. Networks

**Ejemplo:**
```yaml
networks:
  roraima_network:

services:
  postgres:
    networks:
      - roraima_network
  web:
    networks:
      - roraima_network
```

**¿Cómo funciona?**

Docker crea una red interna. Cada servicio tiene su propia IP:

```
Postgres → 172.18.0.2:5432
Redis    → 172.18.0.3:6379
Web      → 172.18.0.4:3000
```

Pero NO necesitas memorizar IPs. Docker resuelve **nombres de servicios** automáticamente:

```ruby
# En database.yml:
# ❌ MAL: localhost:5432
# ✅ BIEN: postgres:5432

adapter: postgresql
host: postgres  # ← Nombre del servicio
```

Docker traduce "postgres" → 172.18.0.2 automáticamente.

### 6. Healthchecks

**Ejemplo:**
```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U postgres"]
  interval: 10s
  timeout: 5s
  retries: 5
  start_period: 10s
```

**¿Qué hace?**

1. Docker ejecuta `pg_isready -U postgres` cada 10 segundos
2. Si responde exitosamente (exit code 0) → ✓
3. Si falla → ✗
4. Después de 5 fallos consecutivos → marca contenedor "unhealthy"

**Estados:**
- `starting` → En los primeros 10s (start_period)
- `healthy` → Healthcheck pasa
- `unhealthy` → Healthcheck falla 5+ veces

**Ver estado:**
```bash
docker compose ps

NAME               STATUS
roraima_postgres   Up (healthy)
roraima_web        Up (unhealthy)  ← Problema
```

### 7. Profiles

**Ejemplo:**
```yaml
tailwindcss:
  profiles:
    - development
```

**Sin profile:**
```bash
docker compose up -d
# NO inicia tailwindcss
```

**Con profile:**
```bash
docker compose --profile development up -d
# SÍ inicia tailwindcss
```

**¿Para qué sirve?**

Servicios opcionales que solo quieres en ciertos contextos:
- `development` → Tailwind watch, debuggers
- `test` → Servicios de testing
- `production` → Ningún profile (solo servicios core)

---

## 📖 Dockerfile Explicado Línea por Línea

Vamos a analizar el Dockerfile mejorado sección por sección:

### Header y Argumentos

```dockerfile
# syntax = docker/dockerfile:1
```

**¿Qué hace?** Especifica la versión de sintaxis de Dockerfile. Permite usar features nuevos.

```dockerfile
ARG RUBY_VERSION=3.2.2
```

**¿Qué es ARG?** Variable de build-time. Se puede sobrescribir:
```bash
docker build --build-arg RUBY_VERSION=3.3.0 .
```

### Stage 1: Base

```dockerfile
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim AS base
```

**Desglose:**
- `FROM` → Imagen base (punto de partida)
- `registry.docker.com/library/ruby` → Repositorio oficial de Docker
- `$RUBY_VERSION-slim` → Versión slim (sin extras, más ligera)
- `AS base` → Nombre de este stage (para referenciarlo después)

```dockerfile
WORKDIR /rails
```

**¿Qué hace?** Equivalente a:
```bash
mkdir -p /rails
cd /rails
```

Todos los comandos siguientes se ejecutan en `/rails`.

```dockerfile
ENV BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT=""
```

**¿Qué es ENV?** Variables de entorno persistentes (disponibles en runtime).

**¿Por qué `\`?** Continuar línea (mejor legibilidad).

```dockerfile
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    postgresql-client \
    libpq-dev \
    libvips \
    build-essential \
    git \
    pkg-config \
    curl && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives
```

**Desglose:**

1. `apt-get update -qq` → Actualiza lista de paquetes (silencioso)
2. `--no-install-recommends` → NO instalar paquetes "sugeridos" (ahorra ~200 MB)
3. `postgresql-client` → Comando `psql`
4. `libpq-dev` → Headers para compilar gema `pg`
5. `libvips` → Procesamiento de imágenes (Active Storage)
6. `build-essential` → gcc, g++, make (compilar gemas nativas)
7. `git` → Algunas gemas se instalan desde repos git
8. `curl` → Para healthchecks
9. `rm -rf /var/lib/apt/lists ...` → **CRÍTICO:** Borra cache de apt (~100 MB)

**¿Por qué todo en un solo RUN?**

Cada `RUN` = una capa nueva. Más capas = imagen más pesada.

```dockerfile
# ❌ MAL (3 capas, 300 MB extra)
RUN apt-get update
RUN apt-get install postgresql-client
RUN rm -rf /var/lib/apt/lists

# ✅ BIEN (1 capa, limpia en misma instrucción)
RUN apt-get update && \
    apt-get install postgresql-client && \
    rm -rf /var/lib/apt/lists
```

### Stage 2: Builder

```dockerfile
FROM base AS builder
```

Hereda todo de `base` (no necesita reinstalar dependencias del sistema).

```dockerfile
COPY Gemfile Gemfile.lock ./
```

**¿Por qué SOLO Gemfile?**

Layer caching. Si Gemfile no cambió, `bundle install` se reutiliza del cache.

```dockerfile
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile
```

**Limpieza:**
- `~/.bundle/` → Config local innecesaria
- `ruby/*/cache` → Archivos .gem ya extraídos
- `bundler/gems/*/.git` → Repos git (solo necesitamos el código)

**Ahorro:** ~200 MB

```dockerfile
COPY . .
```

Ahora sí, copia TODO el código.

### Stage 3: Development

```dockerfile
FROM base AS development
```

**IMPORTANTE:** Hereda de `base`, NO de `builder`.

Construimos desde cero, pero copiando gemas ya compiladas:

```dockerfile
COPY --from=builder /usr/local/bundle /usr/local/bundle
```

**`--from=builder`:** Copia archivos desde OTRO stage.

```dockerfile
ENV RAILS_ENV="development"
```

Variables específicas de desarrollo.

```dockerfile
RUN useradd rails --create-home --shell /bin/bash
```

**¿Por qué usuario no-root?**

Seguridad. Si un atacante compromete el contenedor, NO tiene permisos de root.

```dockerfile
RUN mkdir -p /rails/tmp /rails/log /rails/storage && \
    chown -R rails:rails /rails
```

Crear directorios y dar ownership a usuario `rails`.

```dockerfile
USER rails:rails
```

**CRÍTICO:** A partir de aquí, todos los comandos se ejecutan como `rails`.

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:3000/up || exit 1
```

**Parámetros:**
- `--interval=30s` → Ejecutar cada 30 segundos
- `--timeout=3s` → Esperar máximo 3 segundos
- `--start-period=40s` → No fallar en los primeros 40 segundos (tiempo de arranque)
- `--retries=3` → Marcar unhealthy después de 3 fallos

**Comando:** `curl -f http://localhost:3000/up`
- Rails 7+ tiene endpoint `/up` que responde 200 OK
- `-f` → Fallar si responde con error (4xx, 5xx)

```dockerfile
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
```

**¿Por qué `-b 0.0.0.0`?**

Por defecto, Rails escucha en `localhost` (127.0.0.1).

```
Dentro del contenedor:
- localhost:3000 ← Solo accesible DENTRO del contenedor
- 0.0.0.0:3000   ← Accesible desde CUALQUIER interfaz

Desde host:
- localhost:3000 → Mapea a 0.0.0.0:3000 del contenedor
```

Sin `-b 0.0.0.0`, no podrías acceder desde el navegador.

### Stage 4: Production

```dockerfile
FROM base AS production
```

```dockerfile
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_WITHOUT="development:test"
```

**Variables de producción:**
- `BUNDLE_DEPLOYMENT="1"` → Falla si Gemfile.lock desactualizado (seguridad)
- `BUNDLE_WITHOUT="development:test"` → NO instalar estas gemas (ahorra espacio)

```dockerfile
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /rails /rails
```

Copia gemas Y código desde `builder`.

```dockerfile
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile
```

**¿Por qué DUMMY?**

`assets:precompile` inicializa Rails, que requiere `SECRET_KEY_BASE`.

En build-time no tenemos el secret real (variable de runtime).

`DUMMY=1` permite precompilar sin secret.

**Resultado:**
- CSS minificado: `application-abc123.css`
- JS minificado: `application-def456.js`

---

## 🎯 Resumen de Conceptos Clave

### 1. Flujo Completo Docker Compose

```
docker compose up
  ↓
1. Crea red "roraima_network"
  ↓
2. Crea volúmenes (postgres_data, redis_data, storage_data)
  ↓
3. Construye imágenes (si no existen)
  ↓
4. Inicia servicios en orden (depends_on)
  ↓
5. Ejecuta healthchecks
  ↓
6. Marca servicios como "healthy"
  ↓
7. App disponible en localhost:3000
```

### 2. Hot-Reload Explicado

```
┌─────────────────────────────────────────┐
│  Host (tu computadora)                  │
│                                         │
│  Editor (VS Code)                       │
│  ↓                                      │
│  Guardas archivo.rb                     │
│  ↓                                      │
│  Bind mount (.:/rails:cached)           │
│  sincroniza automáticamente             │
│  ↓                                      │
├─────────────────────────────────────────┤
│  Contenedor Docker                      │
│                                         │
│  /rails/app/models/package.rb (nuevo)  │
│  ↓                                      │
│  Spring (preloader) detecta cambio     │
│  ↓                                      │
│  Recarga código automáticamente         │
│  ↓                                      │
│  Próximo request usa código nuevo      │
└─────────────────────────────────────────┘

Refrescas navegador → ves cambios
```

### 3. Persistencia de Datos

```
docker compose down
  ↓
Contenedores eliminados ✗
Imágenes conservadas ✓
Volúmenes conservados ✓
  ↓
docker compose up
  ↓
Recrea contenedores
Conecta volúmenes existentes
  ↓
Datos de DB intactos ✓
```

**Para borrar datos:**
```bash
docker compose down -v  # ⚠️ Borra volúmenes
```

---

## 🔗 Referencias y Recursos

### Documentación Oficial

- **Docker Docs**: https://docs.docker.com/
- **Docker Compose**: https://docs.docker.com/compose/
- **Rails + Docker**: https://guides.rubyonrails.org/getting_started_with_docker.html
- **PostgreSQL Docker**: https://hub.docker.com/_/postgres
- **Redis Docker**: https://hub.docker.com/_/redis

### Comandos de Referencia Rápida

```bash
# Ver ayuda de Docker Compose
docker compose --help

# Ver comandos disponibles
docker compose ps --help

# Ver imágenes disponibles
docker images

# Ver volúmenes
docker volume ls

# Ver networks
docker network ls

# Inspeccionar contenedor
docker inspect roraima_web

# Ver uso de recursos en tiempo real
docker stats
```

---

## 📞 Soporte y Troubleshooting

Si tienes problemas:

1. **Revisa la sección [Troubleshooting](#-troubleshooting)**
2. **Verifica logs**: `docker compose logs -f <servicio>`
3. **Verifica estado**: `docker compose ps`
4. **Prueba reinicio limpio**: `docker compose down -v && ./bin/docker-setup`
5. **Consulta el plan original**: `/home/omen/.claude/plans/adaptive-noodling-platypus.md`

### Comandos de Diagnóstico

```bash
# Estado completo
docker compose ps

# Logs de todos los servicios
docker compose logs

# Inspeccionar configuración
docker compose config

# Verificar conectividad
docker compose exec web ping postgres
docker compose exec web ping redis

# Verificar variables de entorno
docker compose exec web env | grep -E 'DATABASE|REDIS|RAILS'
```

---

**Creado con ❤️ para desarrolladores que dockerizan por primera vez**

**Versión**: 1.0.0
**Última actualización**: Diciembre 2024
