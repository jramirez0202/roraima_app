# Formato CSV para Carga Masiva

**Última actualización:** Diciembre 2025

Este documento especifica el formato exacto requerido para archivos CSV/XLSX en la carga masiva de paquetes.

## Formato de Archivo

### Extensiones Soportadas

- ✅ **CSV** (`.csv`) - Comma Separated Values
- ✅ **XLSX** (`.xlsx`) - Microsoft Excel

### Encoding

- **Recomendado:** UTF-8 con BOM
- **Soportado:** UTF-8, ISO-8859-1 (Latin-1)

### Delimitador

- **CSV:** Coma (`,`) o Punto y coma (`;`)
- **XLSX:** No aplica (formato binario)

## Estructura de Columnas

### Columnas Requeridas (Admin y Customer)

| Columna | Tipo | Descripción | Ejemplo |
|---------|------|-------------|---------|
| `NRO DE PEDIDO` | Texto | Número de orden del cliente | `ORD-001`, `PED-12345` |
| `DESTINATARIO` | Texto | Nombre completo del destinatario | `Juan Pérez González` |
| `TELÉFONO` | Número | Teléfono móvil chileno | `912345678`, `+56912345678` |
| `DIRECCIÓN` | Texto | Dirección completa de entrega | `Av. Providencia 123, Depto 4B` |
| `COMUNA` | Texto | Comuna de entrega (RM) | `Providencia`, `Santiago Centro` |
| `DESCRIPCIÓN` | Texto | Descripción del paquete | `Ropa`, `Electrónica` |
| `MONTO` | Número | Monto a cobrar (CLP) | `15000`, `0` |
| `CAMBIO` | Texto | ¿Es devolución? | `SÍ`, `NO`, `SI`, `NO` |

### Columnas Opcionales/Específicas

| Columna | Requerido Para | Descripción | Ejemplo |
|---------|----------------|-------------|---------|
| `EMPRESA` | **Admin** | Email del customer owner | `cliente@empresa.com` |

## Especificación Detallada

### NRO DE PEDIDO

**Tipo:** String
**Requerido:** No (opcional)
**Máximo:** 255 caracteres

```csv
# Ejemplos válidos
"ORD-001"
"PED-12345"
"ABC-2024-001"
""  # Vacío es válido
```

**Notas:**
- Si está vacío, no se asigna ningún `order_number`
- Útil para tracking interno del cliente
- No tiene validaciones especiales

---

### DESTINATARIO

**Tipo:** String
**Requerido:** ✅ Sí
**Mínimo:** 3 caracteres
**Máximo:** 255 caracteres

```csv
# ✅ Válidos
"Juan Pérez"
"María José González Rodríguez"
"Empresa ABC S.A."

# ❌ Inválidos
""  # Vacío
"JP"  # Muy corto
```

**Validaciones:**
- Debe contener al menos 3 caracteres
- Se guarda en `customer_name`

---

### TELÉFONO

**Tipo:** String (se normaliza automáticamente)
**Requerido:** ✅ Sí
**Formato Final:** `+569XXXXXXXX` (12 caracteres)

```csv
# Todos estos formatos son aceptados y normalizados
"912345678"        → +56912345678
"+56912345678"     → +56912345678
"56912345678"      → +56912345678
"9 1234 5678"      → +56912345678
"(+56) 9-1234-5678" → +56912345678
9.12345678E8       → +56912345678 (Excel serialization)
```

**Normalización Automática:**

El servicio ejecuta `normalize_phone`:

```ruby
def normalize_phone(phone)
  return nil if phone.blank?

  # Convertir a string (maneja números serializados de Excel)
  phone_str = phone.to_s.strip

  # Remover espacios, guiones, paréntesis
  phone_str = phone_str.gsub(/[\s\-\(\)]/, '')

  # Remover + al inicio si existe
  phone_str = phone_str.gsub(/^\+/, '')

  # Si empieza con 569, agregar +56
  if phone_str.start_with?('569')
    phone_str = "+#{phone_str}"
  # Si empieza con 9 (sin 56), agregar +56
  elsif phone_str.start_with?('9') && phone_str.length == 9
    phone_str = "+56#{phone_str}"
  # Si empieza con 56 pero no tiene +, agregarlo
  elsif phone_str.start_with?('56')
    phone_str = "+#{phone_str}"
  end

  phone_str
end
```

**Validaciones:**
- Formato final: `^\\+569\\d{8}$`
- Exactamente 12 caracteres
- Empieza con `+569`
- Seguido de 8 dígitos

---

### DIRECCIÓN

**Tipo:** String
**Requerido:** ✅ Sí
**Mínimo:** 5 caracteres
**Máximo:** 500 caracteres

```csv
# ✅ Válidos
"Av. Providencia 123"
"Los Alerces 456, Depto 12B, Torre Norte"
"Calle 18 de Septiembre 789, Local 3"

# ❌ Inválidos
""  # Vacío
"Av."  # Muy corto
```

**Notas:**
- Puede incluir número de departamento, piso, local, etc.
- Se guarda en `address`

---

### COMUNA

**Tipo:** String
**Requerido:** ✅ Sí
**Valores Permitidos:** Comunas de Región Metropolitana

```csv
# ✅ Válidos (ejemplos)
"Santiago"
"Santiago Centro"  # Normalizado a "Santiago"
"Providencia"
"Las Condes"
"La Florida"
"Maipú"
"Puente Alto"

# ❌ Inválidos
""  # Vacío
"Valparaíso"  # No está en Región Metropolitana
"Santiago de Chile"  # No existe en la BD
```

**Normalización de Alias:**

El servicio mapea nombres comunes a nombres oficiales:

```ruby
{
  'santiago centro' => 'santiago',
  'stgo' => 'santiago',
  'stgo centro' => 'santiago',
  'estacion central' => 'estación central',
  'ñunoa' => 'ñuñoa',
  'nunoa' => 'ñuñoa',
  'peñalolen' => 'peñalolén',
  'penalolen' => 'peñalolén',
  'maipu' => 'maipú',
  'conchali' => 'conchalí'
}
```

**Proceso:**
1. Busca comuna en Región Metropolitana
2. Normaliza nombre (quita acentos si es necesario)
3. Aplica mapeo de alias
4. Busca en BD con `LOWER(name)`

---

### DESCRIPCIÓN

**Tipo:** String
**Requerido:** No (opcional)
**Máximo:** 500 caracteres

```csv
# Ejemplos
"Paquete con ropa"
"3 cajas de zapatos"
""  # Vacío es válido
```

**Notas:**
- Campo informativo
- No tiene validaciones estrictas

---

### MONTO

**Tipo:** Número (Decimal)
**Requerido:** ✅ Sí
**Mínimo:** 0
**Máximo:** 9,999,999

```csv
# ✅ Válidos
15000
"15000"
"15.000"  # Se normaliza (quita puntos)
"15,000"  # Se normaliza (quita comas)
0         # Válido (sin monto a cobrar)

# ❌ Inválidos
""        # Vacío
"gratis"  # No es número
-100      # Negativo
```

**Normalización:**

```ruby
def normalize_amount(amount)
  return 0 if amount.blank?

  # Remover puntos de miles (15.000 → 15000)
  amount_str = amount.to_s.gsub('.', '')

  # Reemplazar coma decimal por punto (15,50 → 15.50)
  amount_str = amount_str.gsub(',', '.')

  amount_str.to_f
end
```

**Notas:**
- Se guarda en `amount` (integer, centavos)
- Si es 0, no se cobra nada
- Aparece en etiqueta PDF si > 0

---

### CAMBIO (Exchange)

**Tipo:** Boolean (texto convertido)
**Requerido:** ✅ Sí
**Valores Permitidos:** `SÍ`, `SI`, `NO`

```csv
# ✅ Válidos
"SÍ"   → true
"SI"   → true
"Sí"   → true
"sí"   → true
"NO"   → false
"No"   → false
"no"   → false

# ❌ Inválidos
""     # Vacío
"YES"  # Inglés no soportado
"1"    # Números no soportados
```

**Conversión:**

```ruby
def parse_boolean(value)
  return false if value.blank?
  value_normalized = value.to_s.strip.downcase
  ['sí', 'si', 'yes', 'true', '1'].include?(value_normalized)
end
```

**Notas:**
- Se guarda en `exchange` (boolean)
- Si `true`, etiqueta PDF muestra "DEVOLUCIÓN"

---

### EMPRESA (Solo Admin)

**Tipo:** String (Email)
**Requerido:** ✅ Sí (para Admin) / ❌ No (para Customer)
**Validación:** Email válido del customer

```csv
# ✅ Válidos (Admin)
"cliente@empresa.com"
"customer@gmail.com"

# ❌ Inválidos (Admin)
""               # Vacío (Admin lo requiere)
"no-existe@x.cl" # Email no existe en BD
"texto"          # No es email válido
```

**Lógica:**

```ruby
if user.admin?
  # Buscar customer por email
  customer = User.customer.find_by(email: row['EMPRESA'])

  if customer.nil?
    errors << "EMPRESA - email '#{row['EMPRESA']}' no existe"
  end

  # Paquete se asigna al customer
  params[:user_id] = customer.id
else
  # Customer: paquete se asigna a current_user
  params[:user_id] = current_user.id
end
```

---

## Campos Automáticos (No incluir en CSV)

Estos campos se asignan automáticamente y **NO** deben incluirse en el CSV:

| Campo | Valor Automático |
|-------|------------------|
| `FECHA` | `Date.current` (fecha del día de carga) |
| `TRACKING_CODE` | Generado automáticamente (14 dígitos) |
| `STATUS` | `pending_pickup` (estado inicial) |
| `REGION` | Región Metropolitana (hardcoded) |
| `SENDER_EMAIL` | Email del customer owner |
| `COMPANY_NAME` | Nombre de empresa del customer |
| `BULK_UPLOAD_ID` | ID del registro BulkUpload |

---

## Ejemplos Completos

### Archivo CSV para Admin

```csv
NRO DE PEDIDO,DESTINATARIO,TELÉFONO,DIRECCIÓN,COMUNA,DESCRIPCIÓN,MONTO,CAMBIO,EMPRESA
ORD-001,Juan Pérez,912345678,Av. Providencia 123,Providencia,Ropa,15000,NO,cliente@empresa.com
ORD-002,María González,987654321,Los Alerces 456,Las Condes,Electrónica,25000,NO,cliente@empresa.com
ORD-003,Pedro Soto,911111111,Calle Falsa 789,Santiago Centro,Devolución zapatos,0,SÍ,otro-cliente@gmail.com
```

### Archivo CSV para Customer

```csv
NRO DE PEDIDO,DESTINATARIO,TELÉFONO,DIRECCIÓN,COMUNA,DESCRIPCIÓN,MONTO,CAMBIO,EMPRESA
PED-100,Ana Torres,923456789,Av. Grecia 100,Ñuñoa,Documentos,5000,NO,Mi Empresa
PED-101,Carlos Ruiz,934567890,Los Olivos 200,Maipú,Ropa,12000,NO,Mi Empresa
```

### Archivo XLSX

El formato XLSX es idéntico al CSV pero en formato Excel binario. Las columnas y validaciones son las mismas.

**Ventajas de XLSX:**
- Manejo automático de encoding
- Celdas con tipos nativos (números, fechas)
- Fórmulas se evalúan antes de procesar

**Desventajas:**
- Archivo más pesado
- Puede serializar números de forma inesperada (ej: `9.12345678E8`)

---

## Errores Comunes y Soluciones

### Error: "TELÉFONO - formato inválido"

**Causa:** El teléfono no cumple el formato `+569XXXXXXXX`

**Solución:**
- Asegúrate de usar números chilenos móviles (empiezan con 9)
- El servicio normaliza automáticamente, pero verifica que sean 9 dígitos después del código del país

### Error: "COMUNA - no existe en el sistema"

**Causa:** La comuna no existe en Región Metropolitana o tiene typo

**Solución:**
- Verifica ortografía (ej: "Ñuñoa" con Ñ)
- Usa alias soportados (ej: "Santiago Centro" → "Santiago")
- Consulta lista de comunas: `rails runner "Commune.where(region: Region.find_by(name: 'Región Metropolitana')).pluck(:name)"`

### Error: "EMPRESA - email no existe"

**Causa:** (Solo Admin) El email del customer no está registrado

**Solución:**
- Crear el customer primero en `/admin/users/new`
- Verificar ortografía del email
- Revisar que el usuario tenga `role: customer`

### Excel serializa teléfonos como números

**Causa:** Excel convierte `912345678` a `9.12345678E8`

**Solución:**
- Formatear columna TELÉFONO como "Texto" antes de pegar datos
- Agregar apóstrofe antes del número: `'912345678`
- El servicio maneja serialización automáticamente con `to_s`

### Acentos y caracteres especiales

**Causa:** Encoding incorrecto (ISO-8859-1 vs UTF-8)

**Solución:**
- Guardar CSV con encoding UTF-8 con BOM
- En Excel: "Guardar como" → CSV UTF-8
- Usar XLSX si los acentos causan problemas

---

## Validación Previa (Opcional)

Para validar tu archivo **antes** de subirlo, puedes usar el endpoint de preview:

```bash
POST /admin/bulk_uploads/preview
POST /customers/bulk_uploads/preview

# Con formulario HTML o cURL:
curl -X POST \
  -H "Content-Type: multipart/form-data" \
  -F "file=@/path/to/archivo.csv" \
  http://localhost:3000/admin/bulk_uploads/preview
```

Esto ejecuta `BulkPackageValidatorService` sin crear paquetes y retorna un JSON con errores:

```json
{
  "valid_rows": 45,
  "invalid_rows": 5,
  "errors": [
    {
      "row": 17,
      "errors": ["TELÉFONO - formato inválido: 123456"]
    },
    {
      "row": 23,
      "errors": ["COMUNA - no existe en el sistema: Valparaíso"]
    }
  ]
}
```

---

## Límites y Performance

| Métrica | Valor |
|---------|-------|
| Tamaño máximo de archivo | 10 MB |
| Filas máximas recomendadas | 1000 filas |
| Tiempo de procesamiento | ~1 segundo por 10 filas |
| Broadcast de progreso | Cada 5 filas |

**Para archivos grandes (>1000 filas):**
- El procesamiento ocurre en background (Sidekiq)
- El usuario puede cerrar la página
- Se enviará notificación al completar (futuro)

---

## Referencias

- [Guía de Carga Masiva](./carga-masiva.md)
- [Validaciones](./validaciones.md)
- [Troubleshooting](../troubleshooting/errores-comunes.md)
- Código fuente: `app/services/bulk_package_upload_service.rb`
