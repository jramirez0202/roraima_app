# Cierres de Ruta y Reportes

**Última actualización:** Diciembre 2025
**Estado:** 🚧 Funcionalidad Planificada (No Implementada)

Este documento describe la funcionalidad planificada para cierre de rutas y generación de reportes de entregas.

## Visión General

El sistema de cierres permitirá a conductores y administradores finalizar rutas de entrega, generar reportes financieros y auditar entregas diarias.

## Funcionalidades Planificadas

### 1. Cierre de Ruta (Driver)

**Descripción:** Al finalizar su jornada, el conductor podrá cerrar su ruta, generando un reporte automático de:

- ✅ Paquetes entregados
- ❌ Paquetes no entregados (motivo)
- 💰 Total recaudado
- 📊 Estadísticas del día

**Flujo Propuesto:**

```
Driver Dashboard
  └─> "Cerrar Ruta"
      ├─> Revisar paquetes asignados hoy
      ├─> Confirmar entregas y montos
      ├─> Ingresar observaciones
      └─> Generar PDF de cierre
```

**Modelo Sugerido:**

```ruby
class RouteClose < ApplicationRecord
  belongs_to :driver, class_name: 'User'
  belongs_to :zone

  has_many :route_close_packages
  has_many :packages, through: :route_close_packages

  # Campos
  # date: Date (fecha de la ruta)
  # total_packages: Integer (total asignados)
  # delivered_count: Integer
  # failed_count: Integer
  # total_collected: Decimal (CLP)
  # observations: Text
  # status: enum [:open, :closed, :audited]
end
```

---

### 2. Reportes Financieros (Admin)

**Descripción:** Generación de reportes diarios/semanales/mensuales con:

- Total facturado por cliente
- Total recaudado por conductor
- Paquetes pendientes de cobro
- Comisiones de conductores
- Devoluciones y cancelaciones

**Reportes Propuestos:**

#### Reporte Diario de Entregas

```
Fecha: 26/12/2025

┌────────────────────────────────────────────────────┐
│ RESUMEN GENERAL                                    │
├────────────────────────────────────────────────────┤
│ Total Paquetes: 150                                │
│ Entregados: 132 (88%)                              │
│ Reprogramados: 12 (8%)                             │
│ Devoluciones: 6 (4%)                               │
│                                                    │
│ Total Recaudado: $3.450.000                        │
└────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────┐
│ POR CONDUCTOR                                      │
├───────────────────┬────────┬──────────┬────────────┤
│ Conductor         │ Entreg.│ Reprogram│ Recaudado  │
├───────────────────┼────────┼──────────┼────────────┤
│ Juan Pérez        │ 45     │ 3        │ $1.200.000 │
│ María González    │ 38     │ 5        │ $950.000   │
│ Pedro Soto        │ 49     │ 4        │ $1.300.000 │
└───────────────────┴────────┴──────────┴────────────┘

┌────────────────────────────────────────────────────┐
│ POR CLIENTE                                        │
├───────────────────┬────────┬──────────┬────────────┤
│ Cliente           │ Entreg.│ Pendient.│ Facturado  │
├───────────────────┼────────┼──────────┼────────────┤
│ Empresa ABC       │ 65     │ 8        │ $1.800.000 │
│ Tienda XYZ        │ 42     │ 3        │ $980.000   │
│ E-commerce 123    │ 25     │ 1        │ $670.000   │
└───────────────────┴────────┴──────────┴────────────┘
```

#### Reporte Mensual de Comisiones

```
Mes: Diciembre 2025

┌────────────────────────────────────────────────────┐
│ COMISIONES POR CONDUCTOR                           │
├───────────────────┬─────────┬─────────┬────────────┤
│ Conductor         │ Entregas│ Tasa    │ Comisión   │
├───────────────────┼─────────┼─────────┼────────────┤
│ Juan Pérez        │ 450     │ 10%     │ $450.000   │
│ María González    │ 380     │ 10%     │ $380.000   │
│ Pedro Soto        │ 520     │ 12%     │ $624.000   │
└───────────────────┴─────────┴─────────┴────────────┘

Total Comisiones: $1.454.000
```

---

### 3. Auditoría de Entregas (Admin)

**Descripción:** Verificación de entregas con evidencia fotográfica (futuro):

- Foto de paquete entregado
- Firma digital del receptor
- Geolocalización de entrega
- Timestamp de entrega

**Modelo Sugerido:**

```ruby
class DeliveryProof < ApplicationRecord
  belongs_to :package
  belongs_to :delivered_by, class_name: 'User'

  has_one_attached :photo
  has_one_attached :signature

  # Campos
  # latitude: Decimal
  # longitude: Decimal
  # delivered_at: Datetime
  # receiver_name: String
  # receiver_rut: String (opcional)
  # notes: Text
end
```

---

## Implementación Propuesta

### Fase 1: Cierre Básico de Ruta

**Objetivos:**
- [ ] Crear modelo `RouteClose`
- [ ] Interfaz de cierre para drivers
- [ ] Generación de PDF simple con resumen
- [ ] Lista de cierres en Admin

**Estimación:** 1-2 semanas

### Fase 2: Reportes Financieros

**Objetivos:**
- [ ] Reporte diario de entregas (PDF/Excel)
- [ ] Reporte mensual de facturación
- [ ] Dashboard de estadísticas
- [ ] Exportación a CSV

**Estimación:** 2-3 semanas

### Fase 3: Evidencia de Entrega

**Objetivos:**
- [ ] Captura de foto desde app móvil
- [ ] Firma digital táctil
- [ ] Geolocalización automática
- [ ] Validación de evidencias

**Estimación:** 3-4 semanas

### Fase 4: Auditoría y Comisiones

**Objetivos:**
- [ ] Sistema de comisiones por conductor
- [ ] Auditoría de entregas con evidencia
- [ ] Alertas de inconsistencias
- [ ] Cierre contable mensual

**Estimación:** 2-3 semanas

---

## Queries Útiles (Para Reportes)

Aunque la funcionalidad no está implementada, estos queries son útiles para reportes manuales:

### Entregas del Día por Conductor

```ruby
# Paquetes entregados hoy por conductor X
packages = Package.delivered
                  .where(assigned_courier: driver)
                  .where('delivered_at >= ? AND delivered_at < ?',
                         Date.current.beginning_of_day,
                         Date.current.end_of_day)

total_collected = packages.sum(:amount)
count = packages.count
```

### Facturación del Mes por Cliente

```ruby
# Paquetes del cliente X en diciembre
packages = Package.where(user: customer)
                  .where('loading_date >= ? AND loading_date <= ?',
                         Date.current.beginning_of_month,
                         Date.current.end_of_month)

total_delivered = packages.delivered.sum(:amount)
total_pending = packages.where.not(status: [:delivered, :cancelled]).sum(:amount)
```

### Estadísticas Generales

```ruby
# KPIs globales
total_packages = Package.count
delivered_today = Package.delivered.where('delivered_at >= ?', Date.current.beginning_of_day).count
in_transit = Package.in_transit.count
rescheduled = Package.rescheduled.count
success_rate = (delivered_today.to_f / (delivered_today + rescheduled)) * 100

# Recaudación del mes
monthly_revenue = Package.delivered
                         .where('delivered_at >= ?', Date.current.beginning_of_month)
                         .sum(:amount)
```

---

## Mockups (Wireframes)

### Pantalla de Cierre de Ruta (Driver)

```
┌─────────────────────────────────────────────────────┐
│ 🚗 Cerrar Ruta - 26/12/2025                         │
├─────────────────────────────────────────────────────┤
│                                                     │
│ Resumen de tu Jornada:                              │
│                                                     │
│ ┌─────────────────────────────────────────────┐    │
│ │ 📦 Paquetes Asignados: 45                    │    │
│ │ ✅ Entregados: 38                            │    │
│ │ ⏰ Reprogramados: 5                          │    │
│ │ 🔄 Devoluciones: 2                           │    │
│ └─────────────────────────────────────────────┘    │
│                                                     │
│ ┌─────────────────────────────────────────────┐    │
│ │ 💰 Total Recaudado: $950.000                 │    │
│ │ 📊 Comisión Estimada: $95.000 (10%)          │    │
│ └─────────────────────────────────────────────┘    │
│                                                     │
│ Observaciones (opcional):                           │
│ ┌─────────────────────────────────────────────┐    │
│ │ Tráfico intenso en Las Condes, retraso de  │    │
│ │ 30 minutos. Todo lo demás sin novedades.    │    │
│ └─────────────────────────────────────────────┘    │
│                                                     │
│ [ Ver Detalle ] [ Cerrar Ruta y Generar PDF ]      │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Reporte de Admin

```
┌─────────────────────────────────────────────────────┐
│ 📊 Reportes                                         │
├─────────────────────────────────────────────────────┤
│                                                     │
│ Tipo de Reporte:                                    │
│ ┌─────────────────────────────────────────────┐    │
│ │ ☑ Entregas Diarias                           │    │
│ │ ☐ Facturación por Cliente                    │    │
│ │ ☐ Comisiones de Conductores                  │    │
│ │ ☐ Estadísticas Generales                     │    │
│ └─────────────────────────────────────────────┘    │
│                                                     │
│ Período:                                            │
│ Desde: [26/12/2025] Hasta: [26/12/2025]             │
│                                                     │
│ Filtros:                                            │
│ Conductor: [Todos ▼]                                │
│ Cliente: [Todos ▼]                                  │
│ Estado: [Todos ▼]                                   │
│                                                     │
│ [ Generar PDF ] [ Exportar Excel ] [ Ver Preview ] │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## Consideraciones Técnicas

### Generación de PDFs

Usar `Prawn` (ya instalado) para reportes:

```ruby
class ReportGeneratorService
  def initialize(start_date, end_date, filters = {})
    @start_date = start_date
    @end_date = end_date
    @filters = filters
  end

  def generate_daily_report
    pdf = Prawn::Document.new

    pdf.text "Reporte Diario de Entregas", size: 24, style: :bold
    pdf.text "Fecha: #{@start_date.strftime('%d/%m/%Y')}", size: 12
    pdf.move_down 20

    # Resumen general
    # ...

    pdf.render
  end
end
```

### Exportación a Excel

Usar `caxlsx` o `spreadsheet` gem:

```ruby
# Gemfile
gem 'caxlsx'
gem 'caxlsx_rails'

# Controlador
def export_excel
  packages = Package.where(...)

  respond_to do |format|
    format.xlsx {
      response.headers['Content-Disposition'] = 'attachment; filename="reporte.xlsx"'
    }
  end
end

# Vista app/views/admin/reports/export_excel.xlsx.axlsx
wb = xlsx_package.workbook
wb.add_worksheet(name: "Entregas") do |sheet|
  sheet.add_row ["Tracking", "Cliente", "Estado", "Monto"]
  @packages.each do |pkg|
    sheet.add_row [pkg.tracking_code, pkg.customer_name, pkg.status, pkg.amount]
  end
end
```

### Performance

Para reportes de miles de registros:

```ruby
# ✅ Usar find_each para no cargar todo en memoria
Package.where(...).find_each(batch_size: 100) do |package|
  # Procesar package
end

# ✅ Select solo campos necesarios
Package.select(:id, :tracking_code, :amount, :status).where(...)

# ✅ Usar pluck para arrays simples
amounts = Package.delivered.pluck(:amount)
total = amounts.sum
```

---

## Referencias

- [Estados de Paquetes](./estados.md)
- [Arquitectura](../architecture/overview.md)
- [Troubleshooting](../troubleshooting/errores-comunes.md)

---

**Nota:** Esta funcionalidad está planificada pero **no implementada** aún. Los modelos, vistas y servicios mencionados son propuestas y deben ser desarrollados en fases futuras.
