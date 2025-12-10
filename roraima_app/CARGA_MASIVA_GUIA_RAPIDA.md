# 📦 Guía Rápida - Carga Masiva de Paquetes

## 🎯 ¿Cómo Acceder?

### Para Administradores:

1. **Inicia sesión** como admin en: `http://localhost:3000`

2. **Navega** a la página principal de paquetes: `http://localhost:3000/admin/packages`

3. **Verás DOS botones** en la esquina superior derecha:
   - 🟢 **"Carga Masiva"** (botón verde) ← ¡ESTE ES EL NUEVO!
   - 🔵 **"Nuevo Paquete"** (botón azul)

4. **Haz clic en "Carga Masiva"** y serás redirigido a: `http://localhost:3000/admin/bulk_uploads/new`

### Para Clientes (Customers):

1. **Inicia sesión** como customer en: `http://localhost:3000`

2. **Navega** a la página "Mis Paquetes": `http://localhost:3000/customers/packages`

3. **Verás DOS botones** en la esquina superior derecha:
   - 🟢 **"Carga Masiva"** (botón verde) ← ¡ESTE ES EL NUEVO!
   - 🔵 **"Nuevo Paquete"** (botón azul)

4. **Haz clic en "Carga Masiva"** y serás redirigido a: `http://localhost:3000/customers/bulk_uploads/new`

## 📋 Página de Carga Masiva

La página incluye:

1. **Instrucciones claras** de cómo usar la carga masiva
2. **Botón "Descargar Plantilla"** - Descarga CSV de ejemplo con el formato correcto
3. **Tabla con formato esperado** - Muestra todas las columnas requeridas con ejemplos
4. **Formulario de carga** - Drag & drop o selección de archivo CSV/XLSX
5. **Validaciones** - Solo acepta CSV y XLSX

## 🚀 Flujo Completo de Uso

### Paso 1: Preparar el Archivo

1. Haz clic en **"Descargar Plantilla"** (descarga: `/plantilla_carga_masiva.csv`)
2. Abre el archivo en Excel o Google Sheets
3. Llena los datos siguiendo el formato:

**Para Admins:**
```
FECHA,NRO DE PEDIDO,DESTINATARIO,TELÉFONO,DIRECCIÓN,COMUNA,DESCRIPCIÓN,MONTO,CAMBIO,EMPRESA
2025-12-15,ORD-001,Juan Pérez,912345678,Av. Providencia 123,Providencia,Paquete con ropa,15000,NO,cliente@empresa.com
```

**Para Customers:**
```
FECHA,NRO DE PEDIDO,DESTINATARIO,TELÉFONO,DIRECCIÓN,COMUNA,DESCRIPCIÓN,MONTO,CAMBIO,EMPRESA
2025-12-15,ORD-001,Juan Pérez,912345678,Av. Providencia 123,Providencia,Paquete con ropa,15000,NO,Mi Empresa
```

### Paso 2: Subir el Archivo

1. Haz clic en **"Seleccionar archivo"** o arrastra el archivo
2. El archivo se valida automáticamente
3. Haz clic en **"Cargar Paquetes"**

### Paso 3: Procesamiento

**Para Admins:**
- Verás mensaje: "✓ Carga iniciada. Se están procesando los paquetes en segundo plano. Puedes monitorear el progreso en /sidekiq"
- Puedes visitar `http://localhost:3000/sidekiq` para ver el progreso en tiempo real

**Para Customers:**
- Verás mensaje: "✓ Carga iniciada. Se están procesando los paquetes en segundo plano. Te notificaremos cuando termine."

### Paso 4: Verificar Resultados

1. El procesamiento ocurre **en background** (no bloquea la página)
2. Los paquetes se crean automáticamente
3. Si hay errores en algunas filas, se guardan y continúa con las demás
4. Puedes ver los nuevos paquetes en la lista principal

## 📊 Formato del Archivo

| Columna | Tipo | Obligatorio | Ejemplo |
|---------|------|-------------|---------|
| FECHA | Fecha | ✅ | 2025-01-15 |
| NRO DE PEDIDO | Texto | ❌ | ORD-001 |
| DESTINATARIO | Texto | ✅ | Juan Pérez |
| TELÉFONO | Texto | ✅ | 912345678 |
| DIRECCIÓN | Texto | ✅ | Av. Providencia 123 |
| COMUNA | Texto | ✅ | Providencia |
| DESCRIPCIÓN | Texto | ✅ | Paquete con ropa |
| MONTO | Número | ✅ | 15000 |
| CAMBIO | SI/NO | ✅ | NO |
| EMPRESA | Email o Texto | ✅ | cliente@empresa.com (admin) o Mi Empresa (customer) |

**Nota sobre EMPRESA:**
- **Admins**: Debe ser el **email** de un customer existente y activo. Los paquetes se asignarán a ese customer.
- **Customers**: Campo informativo. Todos los paquetes se asignan automáticamente al usuario logueado.

## ✨ Características Especiales

### Transformación Automática de Teléfonos:
- ✅ `912345678` → `+56912345678`
- ✅ `+56912345678` → `+56912345678` (sin cambios)
- ✅ `56912345678` → `+56912345678`
- ✅ Limpia espacios y caracteres especiales

### Validaciones:
- ✅ Todas las columnas son obligatorias (excepto NRO DE PEDIDO)
- ✅ Tracking code se auto-genera si no se proporciona
- ✅ Comuna debe existir en Región Metropolitana
- ✅ Fecha no puede ser en el pasado
- ✅ Monto debe ser ≥ 0
- ✅ CAMBIO acepta: SI, SÍ, S, YES, Y, NO, N

### Manejo de Errores:
- ✅ Si una fila falla, continúa con las demás
- ✅ Se reportan errores específicos (fila y columna)
- ✅ Flash message con resumen al finalizar

## 🔧 Requisitos Técnicos

### Para que funcione correctamente:

1. **Redis debe estar corriendo:**
```bash
redis-server
```

2. **Sidekiq debe estar corriendo:**
```bash
bundle exec sidekiq
```

3. **Rails debe estar corriendo:**
```bash
bin/rails server
```

## 🎨 Botones en la Interfaz

### Admin Panel (`/admin/packages`):
```
┌─────────────────────────────────────────────────┐
│ Paquetes                    [Carga Masiva] [+Nuevo] │
├─────────────────────────────────────────────────┤
│ Todos | Pendiente | Bodega | ...            │
└─────────────────────────────────────────────────┘
```

### Customer Panel (`/customers/packages`):
```
┌─────────────────────────────────────────────────┐
│ Mis Paquetes               [Carga Masiva] [+Nuevo] │
├─────────────────────────────────────────────────┤
│ Lista de paquetes...                           │
└─────────────────────────────────────────────────┘
```

## 🐛 Troubleshooting

### "No puedo ver el botón":
- ✅ Asegúrate de estar autenticado
- ✅ Verifica que estés en `/admin/packages` o `/customers/packages`
- ✅ Refresca la página (Ctrl+R o Cmd+R)

### "El archivo no se procesa":
- ✅ Verifica que Redis esté corriendo: `redis-cli ping`
- ✅ Verifica que Sidekiq esté corriendo: revisa los logs
- ✅ Revisa el formato del archivo CSV

### "Errores de validación":
- ✅ Verifica que las comunas existan en la base de datos
- ✅ Verifica el formato de teléfonos
- ✅ Verifica que las fechas no sean en el pasado

## 📞 Soporte

Para más información, consulta:
- `INSTRUCCIONES_SIDEKIQ.md` - Guía completa de Sidekiq
- `TEST_COVERAGE_REPORT.md` - Tests unitarios
- `/sidekiq` - Monitoreo en tiempo real (solo admins)

¡Listo! Ahora puedes cargar hasta 1500 paquetes por día de forma masiva. 🎉
