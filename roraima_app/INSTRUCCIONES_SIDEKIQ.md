# Instrucciones para Carga Masiva con Sidekiq

## 📦 Instalación de Redis

Para que Sidekiq funcione, necesitas tener Redis instalado y ejecutándose.

### En Linux (Ubuntu/Debian):
```bash
sudo apt update
sudo apt install redis-server
sudo systemctl start redis-server
sudo systemctl enable redis-server
```

### En macOS:
```bash
brew install redis
brew services start redis
```

### Verificar que Redis está corriendo:
```bash
redis-cli ping
# Debería responder: PONG
```

## 🚀 Iniciar Sidekiq

Una vez que Redis esté corriendo, inicia Sidekiq en una terminal separada:

```bash
bundle exec sidekiq
```

O si prefieres usar el comando de Rails:

```bash
bin/sidekiq
```

## 🔍 Monitorear Sidekiq

Puedes monitorear los jobs en tiempo real de dos formas:

### 1. Web UI (Solo para Admins):
Accede a: `http://localhost:3000/sidekiq`

### 2. Logs de Sidekiq:
📝 Comandos Resumidos:

  # Ver errores
  bin/rails bulk_upload:check_errors

  # Crear comunas
  bin/rails bulk_upload:setup_communes

  # Opcional: Abrir consola para inspección manual
  bin/rails console


## 📝 Uso de la Carga Masiva

### Para Admins:
1. Accede a: `http://localhost:3000/admin/bulk_uploads/new`
2. Descarga la plantilla CSV de ejemplo
3. Llena el archivo con tus datos
4. Sube el archivo
5. El procesamiento ocurrirá en background

### Para Customers:
1. Accede a: `http://localhost:3000/customers/bulk_uploads/new`
2. Descarga la plantilla CSV de ejemplo
3. Llena el archivo con tus datos
4. Sube el archivo
5. El procesamiento ocurrirá en background

## 📊 Formato del Archivo CSV/XLSX

El archivo debe tener las siguientes columnas (en este orden exacto):

| Columna | Tipo | Ejemplo | Obligatorio |
|---------|------|---------|-------------|
| FECHA | Fecha | 2024-01-15 | ✅ |
| NRO DE PEDIDO | Texto | ORD-001 | ❌ (se autogenera) |
| DESTINATARIO | Texto | Juan Pérez | ✅ |
| TELÉFONO | Texto | 912345678 | ✅ |
| DIRECCIÓN | Texto | Av. Providencia 123 | ✅ |
| COMUNA | Texto | Providencia | ✅ |
| DESCRIPCIÓN | Texto | Paquete con ropa | ✅ |
| MONTO | Número | 15000 | ✅ |
| CAMBIO | SI/NO | SI | ✅ |
| EMPRESA | Email o Texto | cliente@empresa.com | ✅ |

### Notas Importantes:

1. **EMPRESA**:
   - **Para Admins**: Debe ser el **email** de un customer existente y activo. Los paquetes se asignarán a ese customer.
   - **Para Customers**: Campo informativo únicamente. Todos los paquetes se asignan al usuario logueado.

2. **Teléfonos**: Se normalizarán automáticamente. Puedes usar:
   - `912345678` → se convierte a `+56912345678`
   - `+56912345678` → se mantiene igual
   - `56912345678` → se convierte a `+56912345678`

3. **Comunas**: Deben existir en la base de datos de la Región Metropolitana.

4. **CAMBIO**: Acepta valores como: SI, SÍ, S, NO, N (case-insensitive)

5. **Región**: Siempre se asigna "Región Metropolitana" automáticamente.

## 🐛 Troubleshooting

### Redis no conecta:
```bash
# Verificar que Redis está corriendo
sudo systemctl status redis-server

# Si no está corriendo, iniciarlo
sudo systemctl start redis-server
```

### Sidekiq no procesa jobs:
1. Verifica que Sidekiq esté corriendo
2. Revisa los logs en la terminal de Sidekiq
3. Verifica la configuración en `config/initializers/sidekiq.rb`

### Errores de validación en los paquetes:
Los errores se guardan en el modelo `BulkUpload` en el campo `error_details` (JSONB).
Puedes consultar estos errores desde la consola de Rails:

```ruby
# En rails console
bulk_upload = BulkUpload.last
puts bulk_upload.formatted_errors
```

## 📈 Performance

- El sistema procesa las filas en batches
- Los errores en una fila no detienen el procesamiento de las demás
- Todas las operaciones son transaccionales por fila
- Se recomienda no subir más de 5000 filas por archivo

## 🔧 Configuración Avanzada

### Cambiar el número de workers de Sidekiq:
Edita `config/sidekiq.yml`:

```yaml
:concurrency: 10  # Cambia este número según tus necesidades
```

### Cambiar el timeout de procesamiento:
Edita `config/sidekiq.yml`:

```yaml
:timeout: 60  # Segundos
```

### Cambiar la URL de Redis:
Edita `config/initializers/sidekiq.rb` o usa una variable de entorno:

```bash
export REDIS_URL=redis://localhost:6379/0
```

## 📚 Recursos Adicionales

- [Documentación de Sidekiq](https://github.com/mperham/sidekiq/wiki)
- [Documentación de Redis](https://redis.io/documentation)
- [Gema Roo (para parsear Excel)](https://github.com/roo-rb/roo)

## 🎯 Ejemplo Completo

1. **Iniciar Redis** (en terminal 1):
   ```bash
   redis-server
   ```

2. **Iniciar Sidekiq** (en terminal 2):
   ```bash
   cd /home/omen/Escritorio/Repos/Rails/Roraima_delivery/roraima_app
   bundle exec sidekiq
   ```

3. **Iniciar Rails** (en terminal 3):
   ```bash
   cd /home/omen/Escritorio/Repos/Rails/Roraima_delivery/roraima_app
   bin/rails server
   ```

4. **Acceder a la aplicación**:
   - App: `http://localhost:3000`
   - Sidekiq UI: `http://localhost:3000/sidekiq` (solo admins)

¡Listo! Ahora puedes comenzar a cargar paquetes masivamente. 🎉
