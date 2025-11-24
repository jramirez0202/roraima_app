# 🚀 Cómo Iniciar la Carga Masiva

## ⚡ Comandos Rápidos (3 Pasos)

### Paso 1: Instalar y Arrancar Redis

```bash
# Instalar Redis (solo primera vez)
sudo apt update && sudo apt install redis-server

# Iniciar Redis
sudo systemctl start redis-server

# Verificar que funciona
redis-cli ping
# Debe responder: PONG
```

### Paso 2: Iniciar Sidekiq (Terminal 1)

```bash
cd /home/omen/Escritorio/Repos/Rails/Roraima_delivery/roraima_app
bundle exec sidekiq
```

**Déjalo corriendo** - Verás logs como:
```
2025-11-21T19:05:20.699Z pid=188770 tid=3qha INFO: Sidekiq 7.3.9 starting
2025-11-21T19:05:20.699Z pid=188770 tid=3qha INFO: Sidekiq 7.3.9 connecting to Redis
```

### Paso 3: Iniciar Rails (Terminal 2)

```bash
cd /home/omen/Escritorio/Repos/Rails/Roraima_delivery/roraima_app
bin/rails server
```

## ✅ Verificar que Todo Funciona

Ejecuta el script de verificación:

```bash
./check_sidekiq_setup.sh
```

Si todo está bien, verás:
```
🎉 ¡Todo listo! Puedes usar la carga masiva.
```

## 🎯 Usar la Carga Masiva

Una vez que Redis, Sidekiq y Rails estén corriendo:

1. **Navega a:** `http://localhost:3000/admin/packages`
2. **Haz clic en:** Botón verde "Carga Masiva"
3. **Descarga la plantilla** y llénala con tus datos
4. **Sube el archivo** CSV o XLSX
5. **¡Listo!** El procesamiento ocurre en background

## 🔍 Monitorear el Procesamiento

- **Sidekiq Web UI:** `http://localhost:3000/sidekiq` (solo admins)
- **Logs de Sidekiq:** Terminal donde ejecutaste `bundle exec sidekiq`
- **Logs de Rails:** Terminal donde ejecutaste `bin/rails server`

## 🛑 Detener los Servicios

Cuando termines:

```bash
# Detener Sidekiq
Ctrl+C en la terminal de Sidekiq

# Detener Rails
Ctrl+C en la terminal de Rails

# Detener Redis (opcional)
sudo systemctl stop redis-server
```

## 🐛 Solución de Problemas

### Error: "Connection refused - connect(2) for 127.0.0.1:6379"

**Causa:** Redis no está corriendo

**Solución:**
```bash
sudo systemctl start redis-server
redis-cli ping  # Verificar
```

### Error: "RedisClient::CannotConnectError"

**Causa:** Sidekiq no puede conectarse a Redis

**Solución:**
1. Verificar que Redis esté corriendo: `redis-cli ping`
2. Reiniciar Sidekiq: Ctrl+C y luego `bundle exec sidekiq`

### Sidekiq no procesa los jobs

**Solución:**
1. Verificar que Sidekiq esté corriendo: `pgrep -f sidekiq`
2. Revisar logs en la terminal de Sidekiq
3. Verificar la cola: visita `http://localhost:3000/sidekiq`

## 📝 Estructura de 3 Terminales

Para trabajar cómodamente, usa 3 terminales:

```
Terminal 1: Redis (opcional, puede correr como servicio)
$ redis-server

Terminal 2: Sidekiq
$ bundle exec sidekiq

Terminal 3: Rails
$ bin/rails server
```

## 🎉 ¡Ya Está!

Con estos 3 servicios corriendo, puedes:

✅ Cargar archivos CSV/XLSX masivamente
✅ Procesar 1500+ paquetes por día
✅ Monitorear en tiempo real vía Sidekiq Web
✅ Ver logs detallados de cada procesamiento

---

**Nota:** Redis solo necesita instalarse una vez. Después solo hay que iniciarlo.
