# Rutas y Namespacing

**Última actualización:** Diciembre 2025

Este documento describe la estructura de rutas y namespaces en Roraima Delivery.

## Estructura de Namespaces

La aplicación usa namespacing estricto para separar los tres roles:

```
┌─────────────────────────────────────────┐
│          ApplicationController          │
│  - authenticate_user!                   │
│  - current_user                         │
└──────────────┬──────────────────────────┘
               │
     ┌─────────┼─────────┐
     │         │         │
     ▼         ▼         ▼
  Admin::  Customers:: Drivers::
```

## Rutas por Namespace

### Admin Routes (`/admin`)

```ruby
namespace :admin do
  resources :packages do
    member do
      patch :change_status
      patch :assign_courier
    end
    collection do
      post :bulk_assign
      post :generate_labels
    end
  end

  resources :drivers
  resources :zones
  resources :users
  resources :bulk_uploads, only: [:index, :show, :new, :create]
  resource :settings, only: [:show, :update]

  root to: "packages#index"
end
```

**Rutas Principales:**

| Ruta | Acción | Descripción |
|------|--------|-------------|
| `GET /admin` | `packages#index` | Dashboard principal |
| `GET /admin/packages` | `packages#index` | Lista de paquetes |
| `GET /admin/packages/:id` | `packages#show` | Detalle de paquete |
| `PATCH /admin/packages/:id/change_status` | `packages#change_status` | Cambiar estado |
| `PATCH /admin/packages/:id/assign_courier` | `packages#assign_courier` | Asignar conductor |
| `POST /admin/packages/bulk_assign` | `packages#bulk_assign` | Asignación masiva |
| `POST /admin/packages/generate_labels` | `packages#generate_labels` | Generar etiquetas PDF |
| `GET /admin/drivers` | `drivers#index` | Lista de conductores |
| `GET /admin/zones` | `zones#index` | Lista de zonas |
| `GET /admin/bulk_uploads/new` | `bulk_uploads#new` | Carga masiva |

---

### Customer Routes (`/customers`)

```ruby
scope module: 'customers', as: 'customers' do
  resources :packages, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
    collection do
      post :generate_labels
    end
  end

  resources :bulk_uploads, only: [:index, :show, :new, :create]

  resource :profile, only: [:show, :edit, :update], controller: 'profiles'

  root to: "index#index", as: :root
end
```

**Rutas Principales:**

| Ruta | Acción | Descripción |
|------|--------|-------------|
| `GET /customers` | `index#index` | Dashboard customer |
| `GET /customers/packages` | `packages#index` | Mis paquetes |
| `GET /customers/packages/:id` | `packages#show` | Detalle de paquete |
| `GET /customers/packages/new` | `packages#new` | Crear paquete |
| `POST /customers/packages` | `packages#create` | Guardar paquete |
| `POST /customers/packages/generate_labels` | `packages#generate_labels` | Generar etiquetas |
| `GET /customers/bulk_uploads/new` | `bulk_uploads#new` | Carga masiva |
| `GET /customers/profile` | `profiles#show` | Ver perfil |
| `GET /customers/profile/edit` | `profiles#edit` | Editar perfil |

---

### Driver Routes (`/drivers`)

```ruby
namespace :drivers do
  resources :packages, only: [:index, :show] do
    member do
      patch :mark_as_delivered
      patch :mark_as_failed
    end
  end

  resource :dashboard, only: [:show]
  resource :profile, only: [:show, :edit, :update], controller: 'profiles'

  root to: "dashboard#show"
end
```

**Rutas Principales:**

| Ruta | Acción | Descripción |
|------|--------|-------------|
| `GET /drivers` | `dashboard#show` | Dashboard driver |
| `GET /drivers/packages` | `packages#index` | Mis paquetes asignados |
| `GET /drivers/packages/:id` | `packages#show` | Detalle de paquete |
| `PATCH /drivers/packages/:id/mark_as_delivered` | `packages#mark_as_delivered` | Marcar entregado |
| `PATCH /drivers/packages/:id/mark_as_failed` | `packages#mark_as_failed` | Registrar intento fallido |
| `GET /drivers/profile` | `profiles#show` | Ver perfil |

---

### Public Routes (Root)

```ruby
# config/routes.rb
root to: "home#index"  # Landing page

devise_for :users, skip: [:registrations]
# Login: /users/sign_in
# Logout: /users/sign_out
# (Registration disabled - admins create users)

get '/sidekiq', to: redirect { |_, request|
  if request.env['warden'].user&.admin?
    '/sidekiq'
  else
    '/'
  end
}

mount Sidekiq::Web => '/sidekiq' # Only accessible to admins
```

**Rutas Principales:**

| Ruta | Acción | Descripción |
|------|--------|-------------|
| `GET /` | `home#index` | Landing page pública |
| `GET /users/sign_in` | `devise/sessions#new` | Login |
| `POST /users/sign_in` | `devise/sessions#create` | Autenticar |
| `DELETE /users/sign_out` | `devise/sessions#destroy` | Logout |
| `GET /sidekiq` | `Sidekiq::Web` | Monitor de jobs (admin only) |

---

## Redirects por Rol

Después del login, los usuarios son redirigidos según su rol:

```ruby
# app/controllers/application_controller.rb
def after_sign_in_path_for(resource)
  if resource.admin?
    admin_root_path  # /admin
  elsif resource.driver?
    drivers_root_path  # /drivers
  else
    customers_root_path  # /customers
  end
end
```

**Flujo:**

1. Usuario ingresa a `/`
2. Click en "Iniciar Sesión" → `/users/sign_in`
3. Ingresa credenciales → POST `/users/sign_in`
4. Devise autentica
5. Redirect según rol:
   - Admin → `/admin`
   - Customer → `/customers`
   - Driver → `/drivers`

---

## Helpers de Rutas

Rails genera helpers automáticamente:

### Admin Helpers

```ruby
admin_root_path                 # /admin
admin_packages_path             # /admin/packages
admin_package_path(@package)    # /admin/packages/:id
new_admin_package_path          # /admin/packages/new
edit_admin_package_path(@pkg)   # /admin/packages/:id/edit

change_status_admin_package_path(@pkg)  # /admin/packages/:id/change_status
assign_courier_admin_package_path(@pkg) # /admin/packages/:id/assign_courier

admin_drivers_path              # /admin/drivers
admin_zones_path                # /admin/zones
```

### Customer Helpers

```ruby
customers_root_path             # /customers
customers_packages_path         # /customers/packages
customers_package_path(@pkg)    # /customers/packages/:id
new_customers_package_path      # /customers/packages/new

generate_labels_customers_packages_path  # /customers/packages/generate_labels
customers_profile_path          # /customers/profile
```

### Driver Helpers

```ruby
drivers_root_path               # /drivers
drivers_packages_path           # /drivers/packages
drivers_package_path(@pkg)      # /drivers/packages/:id

mark_as_delivered_drivers_package_path(@pkg)  # /drivers/packages/:id/mark_as_delivered
mark_as_failed_drivers_package_path(@pkg)     # /drivers/packages/:id/mark_as_failed

drivers_profile_path            # /drivers/profile
```

---

## Controladores Base por Namespace

### Admin::BaseController

```ruby
class Admin::BaseController < ApplicationController
  before_action :require_admin!

  private

  def require_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "Acceso no autorizado"
    end
  end
end
```

**Herencia:**

```ruby
class Admin::PackagesController < Admin::BaseController
  # Automáticamente protegido con require_admin!
end
```

### Customers::ApplicationController

No tiene filtro especial (todos los usuarios autenticados pueden acceder), pero usa `policy_scope` para limitar datos:

```ruby
class Customers::PackagesController < ApplicationController
  def index
    @packages = policy_scope(Package)  # Solo paquetes del current_user
  end
end
```

### Drivers::BaseController

```ruby
module Drivers
  class BaseController < ApplicationController
    before_action :require_driver!

    private

    def require_driver!
      unless current_user&.driver?
        redirect_to root_path, alert: "Acceso no autorizado"
      end
    end
  end
end
```

---

## Scopes de Autorización

Las políticas (Pundit) definen qué datos ve cada rol:

```ruby
# app/policies/package_policy.rb
class Scope < Scope
  def resolve
    if user.admin?
      scope.all  # Admin ve TODOS los paquetes
    elsif user.driver?
      scope.where(assigned_courier: user)  # Driver solo sus asignados
    else
      scope.where(user: user)  # Customer solo los suyos
    end
  end
end
```

**Uso en controladores:**

```ruby
# Admin
@packages = policy_scope(Package)  # Todos
@packages = Package.all  # Equivalente para admin

# Customer
@packages = policy_scope(Package)  # Solo where(user: current_user)

# Driver
@packages = policy_scope(Package)  # Solo where(assigned_courier: current_user)
```

---

## URLs Completas

Suponiendo dominio: `https://roraima.cl`

| Rol | URL |
|-----|-----|
| **Admin** | |
| Dashboard | `https://roraima.cl/admin` |
| Paquetes | `https://roraima.cl/admin/packages` |
| Conductores | `https://roraima.cl/admin/drivers` |
| Zonas | `https://roraima.cl/admin/zones` |
| Carga Masiva | `https://roraima.cl/admin/bulk_uploads/new` |
| Sidekiq | `https://roraima.cl/sidekiq` |
| **Customer** | |
| Dashboard | `https://roraima.cl/customers` |
| Mis Paquetes | `https://roraima.cl/customers/packages` |
| Nuevo Paquete | `https://roraima.cl/customers/packages/new` |
| Carga Masiva | `https://roraima.cl/customers/bulk_uploads/new` |
| Perfil | `https://roraima.cl/customers/profile` |
| **Driver** | |
| Dashboard | `https://roraima.cl/drivers` |
| Mis Paquetes | `https://roraima.cl/drivers/packages` |
| Perfil | `https://roraima.cl/drivers/profile` |

---

## Testing de Rutas

```ruby
# test/controllers/admin/packages_controller_test.rb
test "should get index as admin" do
  sign_in_as_admin
  get admin_packages_url
  assert_response :success
end

test "should redirect non-admin" do
  sign_in_as_user(create(:user, :customer))
  get admin_packages_url
  assert_redirected_to root_path
end
```

---

## Troubleshooting

### Error: No route matches

**Causa:** Helper de ruta incorrecto para el namespace

```ruby
# ❌ INCORRECTO
packages_path  # Genera /packages (no existe)

# ✅ CORRECTO
admin_packages_path      # /admin/packages
customers_packages_path  # /customers/packages
drivers_packages_path    # /drivers/packages
```

### Error: Unauthorized redirect loop

**Causa:** Redirect apunta a ruta protegida que redirige nuevamente

```ruby
# ❌ MAL (loop infinito si no es admin)
def require_admin!
  redirect_to admin_root_path unless current_user&.admin?
end

# ✅ BIEN (redirige a ruta pública)
def require_admin!
  redirect_to root_path unless current_user&.admin?
end
```

### Ver todas las rutas

```bash
rails routes | grep admin
rails routes | grep customers
rails routes | grep drivers
rails routes | less
```

---

## Referencias

- [Arquitectura - Controllers](../architecture/overview.md#namespacing-de-controladores)
- [CLAUDE.md](../../CLAUDE.md) - Sección "Controller Namespacing"
- Código fuente:
  - `config/routes.rb`
  - `app/controllers/admin/base_controller.rb`
  - `app/controllers/drivers/base_controller.rb`
