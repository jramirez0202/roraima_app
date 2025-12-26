# Validaciones de Carga Masiva

**Última actualización:** Diciembre 2025

Este documento detalla todas las validaciones que se ejecutan durante la carga masiva de paquetes.

## Proceso de Validación

La validación ocurre en dos etapas:

1. **Validación de Archivo** - Antes de procesar
2. **Validación Row-by-Row** - Durante el procesamiento

```
Usuario sube CSV/XLSX
        │
        ▼
Validación de Archivo
├─ Extensión válida (.csv, .xlsx)
├─ Tamaño < 10 MB
└─ Headers correctos
        │
        ▼
     ✅ Válido
        │
        ▼
Procesamiento Row-by-Row
├─ Validar row 1
│  ├─ Campos requeridos
│  ├─ Formatos correctos
│  ├─ Referencias válidas (comuna, customer)
│  └─ ✅ / ❌
├─ Validar row 2
│  └─ ...
└─ Validar row N
        │
        ▼
Crear Paquetes (solo rows válidas)
        │
        ▼
Generar Reporte de Errores
```

## Validaciones de Archivo

### 1. Extensión de Archivo

**Regla:** Solo `.csv` y `.xlsx`

```ruby
ALLOWED_EXTENSIONS = ['.csv', '.xlsx']

def valid_file_extension?(filename)
  extension = File.extname(filename).downcase
  ALLOWED_EXTENSIONS.include?(extension)
end
```

**Errores:**

```
❌ "archivo.txt" → Extensión no permitida
❌ "archivo.doc" → Extensión no permitida
✅ "archivo.csv" → Válido
✅ "archivo.xlsx" → Válido
```

---

### 2. Tamaño de Archivo

**Regla:** Máximo 10 MB

```ruby
MAX_FILE_SIZE = 10.megabytes

def valid_file_size?(file)
  file.size <= MAX_FILE_SIZE
end
```

**Errores:**

```
❌ 15 MB → Archivo demasiado grande
✅ 2 MB → Válido
```

---

### 3. Headers Correctos

**Regla:** Debe tener headers requeridos (normalización automática)

```ruby
REQUIRED_HEADERS = [
  'NRO DE PEDIDO', 'DESTINATARIO', 'TELÉFONO',
  'DIRECCIÓN', 'COMUNA', 'DESCRIPCIÓN',
  'MONTO', 'CAMBIO'
]

REQUIRED_HEADERS_ADMIN = REQUIRED_HEADERS + ['EMPRESA']

def normalize_header(header)
  # Quitar acentos, downcase, strip
  I18n.transliterate(header.to_s.strip.downcase)
end
```

**Headers Aceptados (con normalización):**

```csv
# Todos estos son equivalentes:
"NRO DE PEDIDO" → "nro de pedido"
"Nro. de Pedido" → "nro de pedido"
"NÚMERO DE PEDIDO" → "numero de pedido" (alias)
"numero de pedido" → "numero de pedido"

"TELÉFONO" → "telefono"
"telefono" → "telefono"
"TELEFONO" → "telefono"
```

**Aliases Soportados:**

```ruby
HEADER_ALIASES = {
  'numero de pedido' => 'nro de pedido',
  'num pedido' => 'nro de pedido',
  'cliente' => 'destinatario',
  'nombre' => 'destinatario',
  'telefono' => 'telefono',
  'fono' => 'telefono',
  'celular' => 'telefono',
  'direccion' => 'direccion',
  'monto a cobrar' => 'monto',
  'cobro' => 'monto',
  'devolucion' => 'cambio',
  'retorno' => 'cambio',
  'email' => 'empresa',
  'correo' => 'empresa'
}
```

---

## Validaciones Row-by-Row

Ejecutadas por `BulkPackageValidatorService`:

### 1. DESTINATARIO

```ruby
# Validación
def validate_customer_name(row, errors)
  customer_name = row['DESTINATARIO']

  if customer_name.blank?
    errors << "DESTINATARIO - no puede estar vacío"
  elsif customer_name.length < 3
    errors << "DESTINATARIO - debe tener al menos 3 caracteres"
  elsif customer_name.length > 255
    errors << "DESTINATARIO - no puede exceder 255 caracteres"
  end
end
```

**Ejemplos:**

```csv
# ✅ Válidos
"Juan Pérez"
"María José González Rodríguez"
"Empresa ABC S.A."

# ❌ Inválidos
""  → "DESTINATARIO - no puede estar vacío"
"JP" → "DESTINATARIO - debe tener al menos 3 caracteres"
```

---

### 2. TELÉFONO

```ruby
# Validación
def validate_phone(row, errors)
  phone = row['TELÉFONO']

  if phone.blank?
    errors << "TELÉFONO - no puede estar vacío"
    return
  end

  # Normalizar
  normalized_phone = normalize_phone(phone)

  # Validar formato final
  unless normalized_phone.match?(/^\+569\d{8}$/)
    errors << "TELÉFONO - formato inválido: #{phone}. Debe ser número chileno móvil (9 dígitos)"
  end
end
```

**Ejemplos:**

```csv
# ✅ Válidos (todos normalizados a +56912345678)
"912345678"
"+56912345678"
"56912345678"
"9 1234 5678"
"(+56) 9-1234-5678"

# ❌ Inválidos
""  → "TELÉFONO - no puede estar vacío"
"12345678" → "TELÉFONO - formato inválido (no empieza con 9)"
"9123"  → "TELÉFONO - formato inválido (muy corto)"
"+56212345678" → "TELÉFONO - formato inválido (teléfono fijo, debe ser móvil)"
```

---

### 3. DIRECCIÓN

```ruby
# Validación
def validate_address(row, errors)
  address = row['DIRECCIÓN']

  if address.blank?
    errors << "DIRECCIÓN - no puede estar vacía"
  elsif address.length < 5
    errors << "DIRECCIÓN - debe tener al menos 5 caracteres"
  elsif address.length > 500
    errors << "DIRECCIÓN - no puede exceder 500 caracteres"
  end
end
```

**Ejemplos:**

```csv
# ✅ Válidos
"Av. Providencia 123"
"Los Alerces 456, Depto 12B"
"Calle 18 de Septiembre 789, Local 3, Centro Comercial"

# ❌ Inválidos
""  → "DIRECCIÓN - no puede estar vacía"
"Av." → "DIRECCIÓN - debe tener al menos 5 caracteres"
```

---

### 4. COMUNA

```ruby
# Validación
def validate_commune(row, errors)
  commune_name = row['COMUNA']

  if commune_name.blank?
    errors << "COMUNA - no puede estar vacía"
    return
  end

  # Buscar comuna
  commune = find_commune(commune_name)

  if commune.nil?
    errors << "COMUNA - no existe en el sistema. Debe ser una comuna de la Región Metropolitana: #{commune_name}"
  end
end

# Búsqueda con normalización
def find_commune(commune_name)
  region = Region.find_by('LOWER(name) = ?', 'región metropolitana')
  return nil unless region

  # Normalizar nombre (aplicar aliases)
  normalized_name = normalize_commune_name(commune_name)

  Commune.where(region_id: region.id)
         .where('LOWER(name) = ?', normalized_name.downcase)
         .first
end
```

**Ejemplos:**

```csv
# ✅ Válidos (todos encuentran la comuna)
"Santiago"
"Santiago Centro" → normalizado a "Santiago"
"Providencia"
"Las Condes"
"Maipú" o "Maipu" → normalizado
"Ñuñoa" o "Nunoa" → normalizado

# ❌ Inválidos
""  → "COMUNA - no puede estar vacía"
"Valparaíso" → "COMUNA - no existe (no está en RM)"
"Santiago de Chile" → "COMUNA - no existe (nombre incorrecto)"
```

---

### 5. MONTO

```ruby
# Validación
def validate_amount(row, errors)
  amount = row['MONTO']

  if amount.blank?
    errors << "MONTO - no puede estar vacío"
    return
  end

  # Normalizar
  normalized_amount = normalize_amount(amount)

  if normalized_amount < 0
    errors << "MONTO - no puede ser negativo: #{amount}"
  elsif normalized_amount > 9_999_999
    errors << "MONTO - excede el máximo permitido (9.999.999): #{amount}"
  end
end

# Normalización
def normalize_amount(amount)
  return 0 if amount.blank?

  # Remover puntos de miles (15.000 → 15000)
  amount_str = amount.to_s.gsub('.', '')

  # Reemplazar coma decimal por punto (15,50 → 15.50)
  amount_str = amount_str.gsub(',', '.')

  amount_str.to_f
end
```

**Ejemplos:**

```csv
# ✅ Válidos
15000 → 15000
"15000" → 15000
"15.000" → 15000
"15,000" → 15000 (interpretado como 15000, NO 15.0)
0 → 0

# ❌ Inválidos
""  → "MONTO - no puede estar vacío"
-100 → "MONTO - no puede ser negativo"
10000000 → "MONTO - excede el máximo permitido"
"gratis" → Error de conversión
```

**IMPORTANTE:** Ambigüedad con coma/punto:
- `"15.000"` → 15000 (punto como separador de miles)
- `"15,00"` → 15.00 (coma como decimal)
- Para evitar ambigüedad, usa números sin separadores: `15000`

---

### 6. CAMBIO (Exchange)

```ruby
# Validación
def validate_exchange(row, errors)
  exchange = row['CAMBIO']

  if exchange.blank?
    errors << "CAMBIO - no puede estar vacío. Debe ser SÍ o NO"
    return
  end

  # Normalizar
  normalized = exchange.to_s.strip.downcase

  unless ['sí', 'si', 'no', 'yes', 'true', 'false', '1', '0'].include?(normalized)
    errors << "CAMBIO - valor inválido: #{exchange}. Debe ser SÍ o NO"
  end
end

# Conversión
def parse_boolean(value)
  return false if value.blank?
  normalized = value.to_s.strip.downcase
  ['sí', 'si', 'yes', 'true', '1'].include?(normalized)
end
```

**Ejemplos:**

```csv
# ✅ Válidos
"SÍ" → true
"SI" → true
"Sí" → true
"sí" → true
"NO" → false
"No" → false
"no" → false

# ❌ Inválidos
""  → "CAMBIO - no puede estar vacío"
"MAYBE" → "CAMBIO - valor inválido"
"2" → "CAMBIO - valor inválido"
```

---

### 7. EMPRESA (Solo Admin)

```ruby
# Validación (solo para Admin)
def validate_empresa(row, errors, user)
  return unless user.admin?

  empresa_email = row['EMPRESA']

  if empresa_email.blank?
    errors << "EMPRESA - no puede estar vacía (email del cliente)"
    return
  end

  # Buscar customer
  customer = User.customer.find_by(email: empresa_email)

  if customer.nil?
    errors << "EMPRESA - email '#{empresa_email}' no existe en el sistema"
  elsif !customer.active?
    errors << "EMPRESA - cliente '#{empresa_email}' está inactivo"
  end
end
```

**Ejemplos (Admin):**

```csv
# ✅ Válidos
"cliente@empresa.com" (existe y está activo)
"customer@gmail.com"

# ❌ Inválidos
""  → "EMPRESA - no puede estar vacía"
"no-existe@x.cl" → "EMPRESA - email no existe"
"inactivo@x.cl" → "EMPRESA - cliente está inactivo"
```

**Nota:** Para Customers, este campo es ignorado (paquetes se asignan a `current_user`).

---

## Validaciones de Modelo (ActiveRecord)

Después de validaciones de servicio, el modelo `Package` ejecuta sus propias validaciones:

```ruby
# app/models/package.rb
validates :tracking_code, presence: true, uniqueness: true
validates :customer_name, presence: true, length: { minimum: 3, maximum: 255 }
validates :phone, presence: true, format: { with: /\A\+569\d{8}\z/ }
validates :address, presence: true, length: { minimum: 5, maximum: 500 }
validates :commune_id, presence: true
validates :region_id, presence: true
validates :user_id, presence: true
validates :amount, numericality: { greater_than_or_equal_to: 0, less_than: 10_000_000 }
validates :status, presence: true, inclusion: { in: statuses.keys }

# Validar que loading_date no sea futuro
validate :loading_date_cannot_be_in_future

def loading_date_cannot_be_in_future
  if loading_date.present? && loading_date > Date.current
    errors.add(:loading_date, "no puede ser una fecha futura")
  end
end
```

**Estos errores son raros** si las validaciones de servicio pasan, pero pueden ocurrir en casos edge.

---

## Manejo de Errores

### Errores de Fila Individual

Cuando una fila tiene errores:

```ruby
# Error agregado a array
errors = []
errors << "TELÉFONO - formato inválido: 123456"
errors << "COMUNA - no existe: Valparaíso"

# Se guarda en BulkUpload.error_details (JSONB)
{
  row: 17,
  errors: ["TELÉFONO - formato inválido: 123456", "COMUNA - no existe: Valparaíso"],
  data: { "DESTINATARIO" => "Juan Pérez", "TELÉFONO" => "123456", ... }
}
```

### Comportamiento del Procesamiento

**Estrategia:** **Parcial** (crear las filas válidas, reportar las inválidas)

```ruby
# Pseudo-código
rows.each_with_index do |row, index|
  errors = validate_row(row)

  if errors.empty?
    package = Package.create!(build_params(row))
    success_count += 1
  else
    error_details << { row: index + 2, errors: errors, data: row }
    error_count += 1
  end
end

# Resultado final
BulkUpload.update(
  status: :completed,
  processed_count: success_count,
  error_count: error_count,
  error_details: error_details
)
```

**Ejemplo:**

```
Archivo con 100 filas:
- 95 filas válidas → 95 paquetes creados ✅
- 5 filas inválidas → 5 errores reportados ❌

Resultado:
- bulk_upload.status = 'completed'
- bulk_upload.processed_count = 95
- bulk_upload.error_count = 5
- bulk_upload.error_details = [{row: 12, errors: [...]}, ...]
```

---

## Reporte de Errores

Al finalizar el procesamiento, el usuario ve:

### Vista de Resultados

```
✅ Carga completada

Resumen:
- Total de filas: 100
- Paquetes creados: 95 ✅
- Filas con errores: 5 ❌

Errores:
┌─────┬────────────────────────────────────────────────────┐
│ Row │ Errores                                            │
├─────┼────────────────────────────────────────────────────┤
│ 12  │ - TELÉFONO - formato inválido: 123456              │
│     │ - COMUNA - no existe: Valparaíso                   │
├─────┼────────────────────────────────────────────────────┤
│ 23  │ - DESTINATARIO - debe tener al menos 3 caracteres  │
├─────┼────────────────────────────────────────────────────┤
│ 45  │ - EMPRESA - email no existe: fake@x.cl             │
├─────┼────────────────────────────────────────────────────┤
│ 67  │ - MONTO - no puede ser negativo: -100              │
├─────┼────────────────────────────────────────────────────┤
│ 89  │ - CAMBIO - valor inválido: MAYBE                   │
└─────┴────────────────────────────────────────────────────┘
```

---

## Testing de Validaciones

### Ejecutar Tests

```bash
# Tests de BulkPackageValidatorService
rails test test/services/bulk_package_validator_service_test.rb

# Tests de BulkPackageUploadService
rails test test/services/bulk_package_upload_service_test.rb
```

### Casos de Test Incluidos

```ruby
# test/fixtures/files/
├── valid_packages.csv         # Todos los campos correctos
├── invalid_packages.csv       # Múltiples errores de validación
├── phone_normalization.csv    # Varios formatos de teléfono
└── empty_file.csv             # Archivo vacío (edge case)
```

**Ejemplos de assertions:**

```ruby
test "rechaza teléfono inválido" do
  row = { 'TELÉFONO' => '123456' }
  errors = []

  service = BulkPackageValidatorService.new(user, row)
  result = service.validate_phone(row, errors)

  assert_includes errors, "TELÉFONO - formato inválido: 123456"
end

test "normaliza teléfono correctamente" do
  row = { 'TELÉFONO' => '9 1234 5678' }
  normalized = service.normalize_phone(row['TELÉFONO'])

  assert_equal '+56912345678', normalized
end
```

---

## Checklist de Validación Completa

Antes de subir un archivo CSV, verifica:

- [ ] Extensión es `.csv` o `.xlsx`
- [ ] Tamaño < 10 MB
- [ ] Headers incluyen todas las columnas requeridas
- [ ] `DESTINATARIO`: No vacío, 3-255 caracteres
- [ ] `TELÉFONO`: Número chileno móvil (9 dígitos)
- [ ] `DIRECCIÓN`: No vacía, 5-500 caracteres
- [ ] `COMUNA`: Existe en Región Metropolitana
- [ ] `MONTO`: Número >= 0, < 10,000,000
- [ ] `CAMBIO`: SÍ o NO
- [ ] `EMPRESA` (Admin): Email válido de customer activo
- [ ] **NO** incluir columna `FECHA` (se asigna automáticamente)

---

## Debugging de Validaciones

### Logs de Rails

```bash
# Ver logs de procesamiento
tail -f log/development.log | grep BulkPackageUploadService
```

### Console de Rails

```ruby
# Ejecutar validación manual
rails console

row = {
  'NRO DE PEDIDO' => 'ORD-001',
  'DESTINATARIO' => 'Juan Pérez',
  'TELÉFONO' => '912345678',
  'DIRECCIÓN' => 'Av. Providencia 123',
  'COMUNA' => 'Providencia',
  'DESCRIPCIÓN' => 'Ropa',
  'MONTO' => '15000',
  'CAMBIO' => 'NO'
}

user = User.find_by(email: 'admin@roraima.cl')
service = BulkPackageValidatorService.new(user, row)
result = service.validate_row(row, 1)

puts "Válido: #{result[:valid]}"
puts "Errores: #{result[:errors]}"
```

---

## Referencias

- [Formato CSV](./formato-csv.md)
- [Guía de Carga Masiva](./carga-masiva.md)
- [Errores Comunes](../troubleshooting/errores-comunes.md)
- Código fuente:
  - `app/services/bulk_package_validator_service.rb`
  - `app/services/bulk_package_upload_service.rb`
  - `app/models/package.rb`
