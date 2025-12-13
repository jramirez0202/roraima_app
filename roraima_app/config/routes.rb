require 'sidekiq/web'

Rails.application.routes.draw do
  # Sidekiq Web UI (solo para admins)
  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  # Devise routes - Disabled registrations and password recovery for security
  devise_for :users, skip: [:registrations, :passwords], controllers: {
    sessions: 'users/sessions'
  }

  # Admin namespace
  namespace :admin do
    resources :users
    resources :drivers do
      member do
        patch :toggle_ready
      end
      collection do
        post :bulk_start_routes
      end
    end

    resources :zones do
      collection do
        get 'communes_by_region/:region_id', to: 'zones#communes_by_region', as: 'communes_by_region'
      end
    end

    resources :packages do
      collection do
        post :generate_labels
        post :bulk_status_change
      end
      member do
        patch :change_status
        patch :assign_courier
        get :status_history
      end
    end

    resources :bulk_uploads, only: [:new, :create, :show]
    resource :settings, only: [:show, :update]

    #
    # ✅ RUTAS SCANNER CORREGIDAS
    #    Ya NO usamos `namespace :scanner` porque buscaba Admin::Scanner (inexistente)
    #    Ahora apuntan directamente al controlador real: Admin::ScannersController
    #
    get  'scanner/warehouse',      to: 'scanners#warehouse_scanner'
    post 'scanner/process',        to: 'scanners#process_scan'
    get  'scanner/session_stats',  to: 'scanners#session_stats'
    post 'scanner/reset_session',  to: 'scanners#reset_session'

    # Ruta corta
    get 'scanner', to: 'scanners#warehouse_scanner'

    # Root admin
    root 'packages#index'
    get 'communes/by_region/:region_id', to: 'communes#by_region', as: 'communes_by_region'
  end

  # Customers namespace
  namespace :customers do
    resources :packages do
      collection do
        post :generate_labels
      end
    end
    resources :bulk_uploads, only: [:new, :create, :show]
    resource :profile, only: [:show, :edit, :update]
    get 'communes/by_region/:region_id', to: 'communes#by_region', as: 'communes_by_region'
  end

  # Drivers namespace
  namespace :drivers do
    resources :packages, only: [:index, :show] do
      member do
        patch :change_status
      end
    end

    resource :profile, only: [:show, :edit, :update]

    post 'start_route', to: 'dashboard#start_route', as: :start_route
    post 'complete_route', to: 'dashboard#complete_route', as: :complete_route

    root 'dashboard#index'
    get 'communes/by_region/:region_id', to: 'communes#by_region', as: 'communes_by_region'
  end

  # Customers dashboard root
  get 'customers', to: 'customers#index', as: :customers_dashboard

  # Redirect root según rol
  authenticated :user do
    root to: redirect { |params, request|
      user = request.env['warden'].user
      if user.admin?
        '/admin'
      elsif user.is_a?(Driver)
        '/drivers'
      else
        '/customers'
      end
    }, as: :authenticated_root
  end

  # Not logged root
  root to: redirect('/users/sign_in')

  # Chrome devtools fix
  get "/.well-known/appspecific/com.chrome.devtools.json", to: proc { [204, {}, []] }
end
