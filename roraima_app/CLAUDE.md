# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Roraima Delivery App is a Chilean delivery and package management system built with Rails 7.1.5. It manages package tracking across all 16 regions of Chile and 345+ communes, supporting multiple user roles (Admin, Customer, Driver) with comprehensive authorization and state management.

## Essential Commands

### Development Server
```bash
# Start development server with Tailwind CSS watch (recommended)
bin/dev

# Or manually (requires two terminals)
rails server        # Terminal 1
rails tailwindcss:watch  # Terminal 2
```

### Database Operations
```bash
# Setup database (create, migrate, seed)
rails db:setup

# Run migrations
rails db:migrate

# Rollback last migration
rails db:rollback

# Reset database (drop, create, migrate, seed)
rails db:reset

# Prepare test database
rails db:test:prepare
```

### Testing
```bash
# Run all tests
rails test

# Run specific test file
rails test test/models/package_test.rb

# Run specific test by line number
rails test test/models/package_test.rb:15

# Run system tests (E2E with Capybara)
rails test:system

# Run model tests only
rails test test/models

# Run service tests only
rails test test/services
```

### Rails Console
```bash
# Development console
rails console
# or: rails c

# Sandbox mode (rollback all changes on exit)
rails console --sandbox
```

### Background Jobs
```bash
# Start Sidekiq for background job processing
bundle exec sidekiq

# Access Sidekiq Web UI (admin only)
# Visit: http://localhost:3000/sidekiq
```

### Asset Management
```bash
# Precompile assets for production
rails assets:precompile

# Clean compiled assets
rails assets:clobber
```

## Architecture Overview

### User Model - Single Table Inheritance (STI)

The application uses STI for user types with a `type` column:

```ruby
User (base class)
├── Admin (role: :admin, type: nil)
├── Customer (role: :customer, type: nil)
└── Driver (role: :driver, type: 'Driver') # STI subclass
```

**Critical Implementation Details:**
- `User.role` is an enum: `admin: 0, customer: 1, driver: 2`
- Legacy `admin` boolean field exists for backward compatibility
- Driver is STI subclass with additional fields: `vehicle_plate`, `vehicle_model`, `vehicle_capacity`, `assigned_zone_id`
- Check user type: `user.admin?` or `user.is_a?(Driver)`
- Active status checked via `user.active?` (affects authentication)

### Package State Machine

Packages follow a strict state transition flow defined in `ALLOWED_TRANSITIONS`:

```
pending_pickup → in_warehouse → in_transit → delivered
                                           ↘ return
                                           ↘ cancelled
                               → rescheduled → in_transit
```

**Key Implementation Points:**
- Terminal states: `delivered`, `picked_up`, `cancelled` (no further transitions without admin override)
- State history tracked in JSONB `status_history` array (immutable, append-only)
- Timestamp fields update based on state: `picked_at`, `shipped_at`, `delivered_at`, `cancelled_at`
- Admin can force transitions with `admin_override: true` flag
- PackageStatusService encapsulates ALL state transition logic

### Authorization Pattern (Pundit)

All authorization is centralized in policies (`app/policies/`):

**PackagePolicy Scope:**
- Admin → sees all packages
- Customer → sees only `user_id == current_user.id`
- Driver → sees only `assigned_courier_id == current_user.id`

**Key Policy Methods:**
- `index?` → All authenticated users
- `show?` → Admin OR owner OR assigned driver
- `create?` → Admin OR Customer (NOT drivers)
- `update?` → Admin OR owner
- `assign_courier?` → Admin only
- `change_status?` → Admin OR assigned driver
- `mark_as_delivered?` → Admin OR assigned driver (if package `in_transit`)

### Service Layer Pattern

Business logic is extracted to services (`app/services/`):

**BulkPackageUploadService:**
- Processes CSV/XLSX files using Roo gem
- Normalizes headers (handles accented Spanish columns)
- Validates row-by-row before creation
- Auto-normalizes phone numbers to `+569XXXXXXXX` format
- Handles Excel serial dates and comma/dot decimal parsing
- Broadcasts progress via Turbo Streams every 5 rows
- Role-aware: Admins upload on behalf of customers (EMPRESA column required), Customers upload for themselves

**PackageStatusService:**
- Encapsulates state machine logic
- Methods: `change_status`, `assign_courier`, `reprogram`, `mark_as_delivered`, `mark_as_devolucion`, `register_failed_attempt`
- Returns `true/false` with errors in `@errors` array
- Validates admin override flag only used by admins

**LabelGeneratorService:**
- Generates A6 size PDF labels using Prawn
- Includes QR code with package JSON data
- Shows amount to collect if `package.amount > 0`
- Shows "DEVOLUCIÓN" flag if `package.exchange == true`

### Database Conventions

**Critical Indexes:**
```ruby
# Composite indexes for common queries
packages.index_packages_on_user_id_and_status
packages.index_packages_on_status_and_assigned_courier_id
packages.index_packages_on_assigned_courier_id_and_assigned_at
users.index_users_on_role_and_active
users.index_users_on_type  # STI
zones.index_zones_on_active

# Trigram index for fast ILIKE searches (pg_trgm extension)
packages.index_packages_on_tracking_code_trigram  # GIN index with gin_trgm_ops
```

**Trigram Index for Tracking Code:**
- Uses PostgreSQL `pg_trgm` extension for fast ILIKE searches
- GIN index with `gin_trgm_ops` operator class
- Allows fast searching by:
  - Primeros dígitos: `PKG-861` → finds `PKG-86169301226465`
  - Últimos dígitos: `465` → finds `PKG-86169301226465`
  - Cualquier parte: `2264` → finds `PKG-86169301226465`
- Performance: O(log n) vs O(n) full table scan
- Created in migration: `20251204213314_add_trigram_index_to_packages_tracking_code.rb`

**JSONB Fields:**
- `packages.status_history` → Array of state transitions with metadata
- `bulk_uploads.error_details` → Array of validation errors per row
- `zones.communes` → Array of commune IDs served by zone

**Important Notes:**
- PostgreSQL runs on port **5433** (non-standard, check `config/database.yml`)
- Always use `.includes()` for eager loading to prevent N+1 queries
- Tracking code format: 14-digit unique string (PKG-XXXXXXXXXXXXXXXX)

## Controller Namespacing

The app uses strict namespacing for role separation:

```
Admin::BaseController
├── before_action :require_admin!
└── Used by: PackagesController, UsersController, DriversController, ZonesController, BulkUploadsController

Customers:: namespace
├── Inherits from ApplicationController
├── Scoped queries: @packages = policy_scope(current_user.packages)
└── Used by: PackagesController, BulkUploadsController, ProfilesController

Drivers:: namespace
├── before_action :require_driver!
├── Scoped queries: @packages = policy_scope(Package.where(assigned_courier: current_user))
└── Used by: PackagesController, DashboardController, ProfilesController
```

**Routing Convention:**
- Admin routes: `/admin/packages`, `/admin/users`, `/admin/drivers`, `/admin/zones`
- Customer routes: `/customers/packages`, `/customers/bulk_uploads`
- Driver routes: `/drivers/packages`, `/drivers/dashboard`

## Key Gotchas and Patterns

### 1. Bulk Upload Logic Differences

**Admin Upload:**
- EMPRESA column is **required** (customer email)
- Creates packages owned by that customer
- Logic in `build_package_params` checks `@user.admin?`

**Customer Upload:**
- EMPRESA column optional/informative
- All packages owned by `current_user`
- Simpler validation flow

### 2. Geographic Data Constraints

- All packages **must** have `region_id` and `commune_id` (NOT NULL)
- Commune lookup currently hardcoded to "Región Metropolitana" in `find_commune` method
- To expand to other regions, update `BulkPackageUploadService#find_commune`
- Uses `LOWER()` SQL function for case-insensitive matching

### 3. Phone Number Normalization

Central normalization in `BulkPackageUploadService#normalize_phone`:
- Removes spaces, hyphens, parentheses
- Adds `+56` if missing
- Handles Excel serialized numbers (converts floats to strings)
- Final format: `+569XXXXXXXX`

### 4. Driver Assignment Validation

From `PackageStatusService#assign_courier`:
```ruby
# Must be Driver type (not admin/customer)
unless courier.is_a?(Driver)
  @errors << "El usuario no es un conductor válido"
  return false
end

# Must be active
unless courier.active?
  @errors << "No se puede asignar un conductor inactivo"
  return false
end
```

### 5. Status History is Immutable

- `status_history` is append-only JSONB array
- Each entry: `{status, previous_status, timestamp, user_id, reason, location, override}`
- Never overwrite previous entries
- Query with PostgreSQL JSON operators: `Package.where("status_history @> ?", [{status: "delivered"}].to_json)`

### 6. Package Bulk Upload Traceability

Since November 2025, all bulk uploaded packages link to their origin:
```ruby
package.bulk_upload  # => BulkUpload instance or nil
bulk_upload.packages  # => All packages from that upload

# Query patterns
Package.where(bulk_upload_id: nil)  # Manual packages
Package.where.not(bulk_upload_id: nil)  # Bulk uploaded
```

## Status Translation Convention (IMPORTANT)

**Last Updated:** December 2025

All status translations are **centralized** in `PackagesHelper::STATUS_TRANSLATIONS`. This eliminates duplication and ensures consistency across the entire application.

### Architecture

```ruby
# app/helpers/packages_helper.rb
STATUS_TRANSLATIONS = {
  pending_pickup: "Pendiente Retiro",
  in_warehouse: "Bodega",
  in_transit: "En Camino",
  # ...
}.freeze
```

**Key Points:**
- ✅ Single source of truth for all translations
- ✅ O(1) lookup performance (Hash vs case statements)
- ✅ Automatic propagation to views, tabs, filters, and JavaScript
- ✅ No duplication between model and helper

### Usage in Views

**ALWAYS use the helper method:**
```erb
<!-- ✅ Correct -->
<%= status_text(package.status) %>
<%= status_text(:delivered) %>

<!-- ❌ Deprecated (still works but avoid in new code) -->
<%= package.status_i18n %>
```

**For select options:**
```erb
<%= f.select :status, status_select_options %>
```

**For JavaScript (already available):**
```javascript
const translations = <%= raw status_translations_json %>;
// Returns: {"delivered": "Entregado", "in_transit": "En Camino", ...}
```

### How It Works

1. **Helper** (`packages_helper.rb`) - Contains centralized constants:
   - `STATUS_TRANSLATIONS` - Spanish translations
   - `STATUS_BADGE_CLASSES` - CSS classes for badges
   - `TAB_ACTIVE_CLASSES` - CSS classes for active tabs
   - `status_text(status)` - Main translation method
   - `status_select_options` - For form selects
   - `status_translations_json` - For JavaScript

2. **Model** (`package.rb`) - Delegates to helper:
   ```ruby
   def status_i18n
     ApplicationController.helpers.status_text(status)
   end
   ```

3. **Views** - Use helper methods consistently:
   - Admin area: Uses `status_text()` everywhere
   - Customers area: Uses `status_text()` everywhere
   - Drivers area: Uses `status_text()` everywhere

### Benefits of This Approach

- **Maintainability:** Change translation in one place, updates everywhere
- **Performance:** Hash lookup O(1) vs case statement O(n)
- **Consistency:** Impossible to have different translations in different views
- **DRY:** Zero code duplication
- **JavaScript Integration:** Translations available to frontend via JSON

## Common Development Tasks

### Add a New Package Status

**IMPORTANT:** Follow these steps in order to maintain the centralized translation system.

1. **Add translation** to `app/helpers/packages_helper.rb`:
   ```ruby
   STATUS_TRANSLATIONS = {
     pending_pickup: "Pendiente Retiro",
     # ... existing statuses
     new_status: "Nuevo Estado"  # ← Add here FIRST
   }.freeze

   STATUS_BADGE_CLASSES = {
     # ... existing statuses
     new_status: "bg-purple-100 text-purple-800"  # ← Add CSS classes
   }.freeze
   ```

2. **Update enum** in `app/models/package.rb`:
   ```ruby
   enum status: {
     pending_pickup: 0,
     # ... existing statuses
     new_status: 10  # Add enum value
   }
   ```

3. **Add allowed transitions** in `ALLOWED_TRANSITIONS`:
   ```ruby
   ALLOWED_TRANSITIONS = {
     in_transit: [:delivered, :return, :rescheduled, :new_status],
     new_status: [:delivered]  # Define valid next states
   }.freeze
   ```

4. **Add migration** if timestamp field needed:
   ```bash
   rails generate migration AddNewStatusAtToPackages new_status_at:datetime
   ```

5. **That's it!** All views, tabs, filters, and JavaScript automatically update:
   - Admin tabs show "Nuevo Estado"
   - Driver filters include "Nuevo Estado"
   - Customer views display "Nuevo Estado"
   - JavaScript bulk operations include "Nuevo Estado"

**What NOT to do:**
- ❌ Don't add case statements with translations (obsolete pattern)
- ❌ Don't hardcode "Nuevo Estado" in any view
- ❌ Don't modify `Package#translate_status` (it delegates to helper)
- ❌ Don't use `status_i18n` in new views (use `status_text()` instead)

### Modify Authorization Rules

Edit `app/policies/package_policy.rb` (NOT controllers):
```ruby
def custom_action?
  user.admin? || (user.customer? && record.user == user)
end
```

Scope changes affect what users see in index views:
```ruby
class Scope < Scope
  def resolve
    if user.admin?
      scope.all
    elsif user.is_a?(Driver)
      scope.where(assigned_courier: user)
    else
      scope.where(user: user)
    end
  end
end
```

### Fix Bulk Upload Issues

Most issues are in `BulkPackageUploadService#build_package_params`:
- Column mapping: Check `normalized_headers` hash
- Data transformation: Check type casting for dates, amounts, booleans
- Validation errors: Check `BulkPackageValidatorService` for preview logic

### Add New Geographic Coverage

1. Update `find_commune` method to search beyond Región Metropolitana
2. Add region data to seeds if new regions needed
3. Update Zone model to support multi-region zones (currently RM-only)

### Debug Permission Errors

1. Check `PackagePolicy` or relevant policy first
2. Verify `current_user.role` matches expected role
3. Check scopes in policy `Scope` class
4. Test in console:
   ```ruby
   user = User.find(123)
   package = Package.find(456)
   PackagePolicy.new(user, package).show?  # => true/false
   ```

## Testing Patterns

### Factory Usage

Factories available in `test/factories/`:
```ruby
# Users
FactoryBot.create(:user)  # Default customer
FactoryBot.create(:user, :admin)
FactoryBot.create(:user, role: :driver)  # But use :driver factory instead
FactoryBot.create(:driver)  # STI Driver with vehicle fields

# Packages
FactoryBot.create(:package)  # With associations
FactoryBot.create(:package, status: :in_transit)
FactoryBot.create(:package, :with_bulk_upload)

# Geographic
FactoryBot.create(:region)
FactoryBot.create(:commune)
FactoryBot.create(:zone)  # With region and communes
```

### Test Helpers

Available in `test/test_helper.rb`:
```ruby
sign_in_as_admin  # Signs in as admin user
sign_in_as_user(user)  # Signs in specific user
```

### Running Specific Tests

```bash
# Single test file
rails test test/models/package_test.rb

# Single test method
rails test test/models/package_test.rb:15

# All model tests
rails test test/models

# All service tests
rails test test/services

# System tests (E2E)
rails test:system
```

## File Organization Quick Reference

```
app/
├── controllers/
│   ├── admin/          # Admin-only controllers (require_admin!)
│   ├── customers/      # Customer-scoped controllers
│   └── drivers/        # Driver-scoped controllers
├── models/
│   ├── user.rb         # Base class, Devise, role enum
│   ├── driver.rb       # STI subclass, vehicle fields
│   ├── package.rb      # State machine, validations
│   ├── bulk_upload.rb  # File upload tracking
│   └── zone.rb         # Geographic zones, JSONB communes
├── policies/           # Pundit authorization (CHECK HERE FIRST)
│   ├── package_policy.rb
│   ├── driver_policy.rb
│   └── zone_policy.rb
├── services/           # Business logic extraction
│   ├── bulk_package_upload_service.rb
│   ├── bulk_package_validator_service.rb
│   ├── label_generator_service.rb
│   └── package_status_service.rb
└── views/
    ├── admin/          # Admin interface
    ├── customers/      # Customer interface
    └── drivers/        # Driver interface

config/
├── routes.rb           # Namespaced routes
└── database.yml        # PostgreSQL on port 5433

db/
├── migrate/            # Migrations (check recent ones for schema changes)
├── seeds.rb            # Regions, communes, zones, test users
└── schema.rb           # Current schema

test/
├── factories/          # FactoryBot test data
├── models/             # Model unit tests
├── services/           # Service unit tests
└── system/             # E2E browser tests
```

## Technology Stack

**Backend:**
- Rails 7.1.5 (Ruby 3.2.2)
- PostgreSQL 12+ (Port 5433)
- Sidekiq 7.0 (background jobs)
- Devise (authentication)
- Pundit (authorization)
- Pagy 6.0 (pagination)
- Roo (CSV/Excel parsing)
- Prawn + rqrcode (PDF + QR generation)

**Frontend:**
- Stimulus JS (interactivity)
- Turbo Rails (SPA-like)
- Tailwind CSS (styling)
- ImportMap (no Node build step)

**Testing:**
- Minitest (framework)
- FactoryBot (test data)
- Capybara + Selenium (system tests)

## Current Project State

Based on git status, recent work includes:
- Added STI for Driver model (type column)
- Created Zone management system
- Refactored package status to English
- Added assignment audit fields (assigned_by, assigned_at, admin_override)
- Implemented bulk upload traceability (bulk_upload_id)
- Multiple documentation files created (ANALISIS, RESUMEN, SISTEMA_DRIVERS_ZONAS)

Untracked files indicate ongoing development of Driver/Zone features.

## Important Configuration Notes

- PostgreSQL uses **port 5433** (non-standard) - check `config/database.yml`
- Devise registration disabled - admins create users via admin interface
- Sidekiq web UI mounted at `/sidekiq` (admin authentication required)
- Active Storage configured for logos, bulk upload files, and generated PDFs
- Rails master key required for credentials - see `config/master.key`
- Tailwind requires `rails tailwindcss:watch` or `bin/dev` for live reloading

## Security Considerations

- Never commit `config/master.key` or `.env` files
- Test user credentials (password123) are for development only
- Admin override actions tracked in package audit trail
- Pundit authorization on all resource controllers
- Active/inactive user status affects authentication
- Driver assignment validates active status before allowing assignment
