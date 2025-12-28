# Sistema de Colores Centralizado - Roraima Delivery App

## 📋 Índice
- [Introducción](#introducción)
- [Estructura de Variables](#estructura-de-variables)
- [Cómo Usar](#cómo-usar)
- [Migración de Código Existente](#migración-de-código-existente)
- [Ejemplos Prácticos](#ejemplos-prácticos)
- [Mantenimiento](#mantenimiento)

---

## 🎨 Introducción

Este sistema centraliza todos los colores de la aplicación en un solo archivo: `colors.css`.

### Beneficios:
- ✅ **Cambios globales fáciles**: Modifica un color en un solo lugar
- ✅ **Consistencia visual**: Todos usan los mismos colores
- ✅ **Mantenimiento simplificado**: No más búsqueda de colores hardcodeados
- ✅ **Compatible con Tailwind**: Convive perfectamente con las clases Tailwind existentes

---

## 📦 Estructura de Variables

### Colores Primarios
```css
--color-primary          /* Azul indigo principal */
--color-success          /* Verde para acciones exitosas */
```

### Colores de Estado (Package Status)
```css
--color-status-pending-*      /* Pendiente Retiro (amarillo) */
--color-status-warehouse-*    /* Bodega (azul claro) */
--color-status-transit-*      /* En Camino (azul oscuro) */
--color-status-delivered-*    /* Entregado (verde) */
--color-status-rescheduled-*  /* Reprogramado (ámbar) */
--color-status-return-*       /* Devolución (naranja) */
--color-status-cancelled-*    /* Cancelado (rojo) */
```

### Colores de Roles (User Roles)
```css
--color-admin-*          /* Admin (slate oscuro) */
--color-customer-*       /* Customer (slate) */
--color-driver-*         /* Driver (teal) */
```

---

## 🚀 Cómo Usar

### Opción 1: Usar clases CSS predefinidas

```erb
<!-- Botones -->
<button class="btn-primary">Nuevo Paquete</button>
<button class="btn-success">Carga Masiva</button>

<!-- Badges de estado -->
<span class="badge-pending">Pendiente Retiro</span>
<span class="badge-delivered">Entregado</span>
<span class="badge-cancelled">Cancelado</span>

<!-- Sidebars -->
<div class="sidebar-admin">...</div>
<div class="sidebar-customer">...</div>
<div class="sidebar-driver">...</div>
```

### Opción 2: Usar variables CSS directamente

```erb
<!-- En estilos inline -->
<div style="background-color: var(--color-primary); color: white;">
  Contenido
</div>

<!-- En atributos de clase con Tailwind -->
<div class="bg-[var(--color-primary)] text-white">
  Contenido
</div>
```

### Opción 3: Crear nuevas clases en tu CSS

```css
/* En tu archivo CSS */
.mi-clase-personalizada {
  background-color: var(--color-status-delivered);
  color: var(--color-status-delivered-text);
  border: 1px solid var(--color-status-delivered-bg);
}
```

---

## 🔄 Migración de Código Existente

### Antes (hardcoded):
```erb
<button class="bg-indigo-600 hover:bg-indigo-700 text-white">
  Nuevo Paquete
</button>

<span class="bg-green-100 text-green-800">
  Entregado
</span>
```

### Después (centralizado):
```erb
<!-- Opción 1: Clase predefinida -->
<button class="btn-primary">
  Nuevo Paquete
</button>

<span class="badge-delivered">
  Entregado
</span>

<!-- Opción 2: Variable CSS con Tailwind -->
<button class="bg-[var(--color-primary)] hover:bg-[var(--color-primary-hover)] text-white">
  Nuevo Paquete
</button>
```

---

## 📚 Ejemplos Prácticos

### Ejemplo 1: Botón de Acción Principal
```erb
<!-- Antes -->
<%= link_to "Crear Paquete", new_package_path,
    class: "bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md" %>

<!-- Después (Opción A - Clase predefinida) -->
<%= link_to "Crear Paquete", new_package_path,
    class: "btn-primary" %>

<!-- Después (Opción B - Variable + Tailwind) -->
<%= link_to "Crear Paquete", new_package_path,
    class: "bg-[var(--color-primary)] hover:bg-[var(--color-primary-hover)] text-white px-4 py-2 rounded-md" %>
```

### Ejemplo 2: Badge de Estado
```erb
<!-- Antes -->
<span class="px-2 py-1 rounded-full text-xs font-semibold bg-green-100 text-green-800">
  <%= status_text(package.status) %>
</span>

<!-- Después -->
<span class="badge-delivered">
  <%= status_text(package.status) %>
</span>
```

### Ejemplo 3: Sidebar Dinámica por Rol
```erb
<!-- Antes -->
<div class="<%= current_user.admin? ? 'bg-slate-800' : 'bg-teal-700' %>">
  ...
</div>

<!-- Después -->
<div class="sidebar-<%= current_user.role %>">
  ...
</div>
```

### Ejemplo 4: Alert/Notification
```erb
<!-- Usar variables para notificaciones -->
<div style="background-color: var(--color-success-notification-bg);
            color: var(--color-success-notification-text);
            border-left: 4px solid var(--color-success-notification);"
     class="p-4 rounded">
  ✓ Paquete creado exitosamente
</div>
```

---

## 🛠️ Mantenimiento

### Cambiar el Color Principal de la App

Edita `app/assets/stylesheets/colors.css`:

```css
:root {
  /* Cambiar de azul indigo a azul cielo */
  --color-primary: #0ea5e9;           /* sky-500 */
  --color-primary-hover: #0284c7;     /* sky-600 */
}
```

### Añadir un Nuevo Color de Estado

```css
:root {
  /* Nuevo estado: En Revisión */
  --color-status-review: #8b5cf6;           /* violet-500 */
  --color-status-review-bg: #ede9fe;        /* violet-100 */
  --color-status-review-text: #5b21b6;      /* violet-800 */
}

/* Clase de badge */
.badge-review {
  background-color: var(--color-status-review-bg);
  color: var(--color-status-review-text);
  padding: 0.25rem 0.75rem;
  border-radius: 9999px;
  font-size: 0.75rem;
  font-weight: 600;
}
```

### Crear Tema Oscuro (Dark Mode)

```css
/* En colors.css */
@media (prefers-color-scheme: dark) {
  :root {
    --color-bg-primary: #1f2937;      /* gray-800 */
    --color-text-primary: #f9fafb;    /* gray-50 */
    /* ... más overrides ... */
  }
}
```

---

## 📝 Notas Importantes

1. **Compatibilidad**: Las variables CSS funcionan en todos los navegadores modernos (IE11+)
2. **Performance**: No hay impacto en performance, las variables se resuelven en el navegador
3. **Tailwind**: Puedes seguir usando Tailwind normalmente, las variables son complementarias
4. **Prioridad**: El archivo `colors.css` se carga primero (`*= require colors`)

---

## 🎯 Próximos Pasos Recomendados

1. ✅ **Crear clases de utilidad adicionales** según necesites
2. ✅ **Migrar vistas gradualmente** usando find/replace
3. ✅ **Documentar colores de marca** en guía de estilo
4. ✅ **Añadir tema oscuro** si es necesario

---

## 🤝 Contribución

Si añades nuevos colores o clases:
1. Documenta el propósito del color
2. Mantén consistencia con los nombres existentes
3. Agrupa por categoría (status, roles, UI, etc.)
4. Actualiza este README si es necesario
