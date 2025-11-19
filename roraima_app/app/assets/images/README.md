# Imágenes de Roraima Delivery

## Logo de la Aplicación

Para que el logo aparezca en las páginas de **Login** y **Registro**, por favor agrega tu archivo de logo aquí:

### Instrucciones:

1. **Nombre del archivo**: `logo.png` (o `logo.jpg`, `logo.svg`)
2. **Ubicación**: Este directorio (`app/assets/images/`)
3. **Tamaño recomendado**:
   - Ancho: 200-400px
   - Alto: Se ajustará automáticamente (máximo 64px en pantalla)
   - Formato: PNG con fondo transparente (recomendado) o JPG

### Ejemplo:

```bash
# Desde la raíz del proyecto:
cp /ruta/a/tu/logo.png app/assets/images/logo.png
```

### Si usas un formato diferente:

Si tu logo es `.jpg` o `.svg`, actualiza las vistas de Devise:

**Archivos a modificar:**
- `app/views/devise/sessions/new.html.erb` (línea 10)
- `app/views/devise/registrations/new.html.erb` (línea 10)

**Cambia:**
```erb
<%= image_tag 'logo.png', alt: 'Roraima Delivery', class: 'h-16 w-auto' %>
```

**Por:**
```erb
<%= image_tag 'logo.svg', alt: 'Roraima Delivery', class: 'h-16 w-auto' %>
```

### Verificación:

Después de agregar el logo, reinicia el servidor Rails:

```bash
bin/dev
```

Luego visita: `http://localhost:3000/users/sign_in`

---

## Otros Assets

Puedes agregar más imágenes aquí para usar en toda la aplicación con `image_tag`.
