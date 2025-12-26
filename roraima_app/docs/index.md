# Documentación de Roraima Delivery

**Última actualización:** Diciembre 2025
**Versión:** 1.0

Bienvenido a la documentación oficial de Roraima Delivery, un sistema de gestión de paquetería y entregas construido con Ruby on Rails.

---

## 📚 Contenido

### 🏗️ Arquitectura

Documentación sobre el diseño y estructura del sistema.

- **[Overview](./architecture/overview.md)** - Visión general de la arquitectura
  - Stack tecnológico
  - Modelo de usuarios (STI)
  - Arquitectura de paquetes
  - Capa de servicios
  - Autorización con Pundit

- **[Decisiones](./architecture/decisions.md)** - Decisiones arquitectónicas importantes (ADR)
  - ADR-001: STI para Drivers
  - ADR-002: JSONB para Comunas
  - ADR-003: Historial de Estados en JSONB
  - ADR-004: Traducciones Centralizadas
  - ADR-005: Índice Trigram
  - ADR-006: Sidekiq para Bulk Uploads
  - ADR-007: Pundit para Autorización

- **[Diagramas](./architecture/diagrams.md)** - Diagramas visuales del sistema
  - ERD (Entidades y Relaciones)
  - Flujo de estados
  - Arquitectura de controladores
  - Arquitectura de servicios
  - Flujo de carga masiva

---

### 🚀 Setup

Guías de instalación y configuración.

- **[Setup Local](./setup/local.md)** - Instalación en entorno de desarrollo
  - Requisitos previos
  - Configuración de PostgreSQL (puerto 5433)
  - Configuración de base de datos
  - Habilitar extensión pg_trgm
  - Iniciar servidor con bin/dev
  - Usuarios de prueba

- **[Setup con Docker](./setup/docker.md)** - Instalación usando contenedores
  - ¿Qué es Docker?
  - Docker Compose
  - Comandos básicos
  - Troubleshooting

- **[Setup de Producción](./setup/production.md)** - Deployment a producción
  - Heroku (recomendado para MVP)
  - VPS (DigitalOcean, Linode, AWS EC2)
  - Configuración de PostgreSQL
  - Backups
  - Monitoreo y logs
  - SSL/TLS

---

### 📦 Carga Masiva (Bulk Upload)

Documentación sobre la funcionalidad de carga masiva de paquetes.

- **[Guía de Carga Masiva](./bulk/carga-masiva.md)** - Cómo usar la carga masiva
  - Acceso (Admin y Customer)
  - Preparar archivo CSV/XLSX
  - Subir archivo
  - Monitorear procesamiento
  - Verificar resultados

- **[Formato CSV](./bulk/formato-csv.md)** - Especificación detallada del formato
  - Extensiones soportadas
  - Estructura de columnas
  - Especificación de cada campo
  - Normalización automática
  - Ejemplos completos
  - Errores comunes

- **[Validaciones](./bulk/validaciones.md)** - Proceso de validación
  - Validación de archivo
  - Validación row-by-row
  - Validaciones de modelo
  - Manejo de errores
  - Reporte de errores
  - Testing

---

### ⚙️ Operaciones

Documentación sobre operaciones diarias del sistema.

- **[Sistema de Estados](./operations/estados.md)** - Máquina de estados de paquetes
  - Estados disponibles (8 estados)
  - Traducciones al español
  - Transiciones permitidas
  - PackageStatusService
  - Historial de estados (JSONB)
  - Admin override
  - Timestamps automáticos
  - Casos de uso

- **[Rutas y Namespacing](./operations/rutas.md)** - Estructura de rutas
  - Admin routes (`/admin`)
  - Customer routes (`/customers`)
  - Driver routes (`/drivers`)
  - Helpers de rutas
  - Controladores base
  - Scopes de autorización

- **[Cierres de Ruta](./operations/cierres.md)** - 🚧 Funcionalidad planificada
  - Cierre de ruta (Driver)
  - Reportes financieros (Admin)
  - Auditoría de entregas
  - Implementación propuesta
  - Mockups

---

### 🔧 Troubleshooting

Guías para solucionar problemas comunes.

- **[Errores Comunes](./troubleshooting/errores-comunes.md)** - Errores frecuentes y soluciones
  - Errores de base de datos
  - Errores de autenticación
  - Errores de carga masiva
  - Errores de Sidekiq
  - Errores de assets/Tailwind
  - Errores de extensiones PostgreSQL
  - Errores de validación
  - Errores de permisos
  - Errores de estado de paquetes
  - Errores de performance

- **[Logs y Monitoreo](./troubleshooting/logs.md)** - Cómo leer y monitorear logs
  - Ubicación de logs
  - Leer logs de Rails
  - Comandos útiles
  - Interpretar logs comunes
  - Logs de Sidekiq
  - Logs de Nginx
  - Performance monitoring
  - Custom logging
  - Log rotation
  - Debugging avanzado

---

### 📖 Otros Recursos

- **[Glosario](./glossary.md)** - Terminología del proyecto
- **[CLAUDE.md](../CLAUDE.md)** - Guía completa para Claude Code (desarrollo con AI)
- **[README.md](../README.md)** - Introducción general del proyecto

---

## 🚦 Quick Start

¿Nuevo en el proyecto? Empieza aquí:

### Desarrollador

1. **[Setup Local](./setup/local.md)** - Instalar entorno de desarrollo
2. **[Architecture Overview](./architecture/overview.md)** - Entender la arquitectura
3. **[CLAUDE.md](../CLAUDE.md)** - Leer guía completa de desarrollo

### Usuario Admin

1. **[Carga Masiva](./bulk/carga-masiva.md)** - Subir paquetes desde CSV
2. **[Sistema de Estados](./operations/estados.md)** - Entender flujo de paquetes
3. **[Errores Comunes](./troubleshooting/errores-comunes.md)** - Solucionar problemas

### DevOps

1. **[Setup de Producción](./setup/production.md)** - Deploy a Heroku o VPS
2. **[Logs y Monitoreo](./troubleshooting/logs.md)** - Monitorear la app
3. **[Troubleshooting](./troubleshooting/errores-comunes.md)** - Resolver incidencias

---

## 📝 Convenciones de Documentación

- **✅** - Funcionalidad implementada y probada
- **🚧** - Funcionalidad planificada, no implementada
- **⚠️** - Advertencia o información importante
- **💡** - Tip o best practice
- **🔴** - Deprecated o no recomendado

---

## 🤝 Contribuir

Para contribuir a la documentación:

1. **Ubicación:** Todos los archivos están en `/docs`
2. **Formato:** Markdown (GitHub Flavored)
3. **Naming:** Usar minúsculas y guiones: `nombre-archivo.md`
4. **Estructura:** Seguir el patrón jerárquico existente
5. **Update:** Actualizar `Última actualización` en el header

### Agregar Nueva Documentación

```bash
# Ubicación según tema
docs/architecture/    # Decisiones técnicas, diagramas
docs/setup/           # Instalación, configuración
docs/bulk/            # Carga masiva
docs/operations/      # Operaciones diarias
docs/troubleshooting/ # Errores y soluciones
```

### Formato de Documentos

```markdown
# Título del Documento

**Última actualización:** Mes Año

Breve descripción del documento.

## Sección 1

Contenido...

### Subsección

Contenido...

## Referencias

- [Documento Relacionado](./ruta.md)
- [Documentación Externa](https://example.com)
```

---

## 🔍 Buscar en la Documentación

### Por Grep (Terminal)

```bash
# Buscar en toda la documentación
grep -r "tracking code" docs/

# Buscar con contexto
grep -rC 3 "PackageStatusService" docs/

# Buscar archivos que contienen término
grep -rl "Sidekiq" docs/
```

### Por GitHub (Web)

Usa la búsqueda de GitHub en el repositorio:
```
STI path:docs/
```

---

## 📊 Estadísticas

**Documentación actual:**

- **Páginas:** 18 archivos .md
- **Palabras:** ~50,000 palabras
- **Secciones:** 5 categorías principales
- **Diagramas:** 6 diagramas ASCII/Mermaid
- **Ejemplos de código:** 150+ snippets

---

## 📅 Historial de Cambios

### Diciembre 2025 - v1.0

- ✅ Reorganización completa de documentación
- ✅ Estructura jerárquica por temas
- ✅ Documentación de arquitectura (overview, decisions, diagrams)
- ✅ Guías de setup (local, docker, producción)
- ✅ Documentación de carga masiva (guía, formato CSV, validaciones)
- ✅ Documentación de operations (estados, rutas, cierres)
- ✅ Troubleshooting (errores comunes, logs)
- ✅ Glosario de términos
- ✅ Índice general (este documento)

---

## 🆘 Ayuda y Soporte

- **Documentación:** Este directorio (`/docs`)
- **CLAUDE.md:** Guía para desarrollo con Claude Code
- **GitHub Issues:** Reportar bugs o sugerencias
- **Logs:** Ver [Logs y Monitoreo](./troubleshooting/logs.md)

---

## 📜 Licencia

Este proyecto y su documentación son propiedad de Roraima Delivery.

---

**Última actualización:** Diciembre 2025
