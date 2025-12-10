require 'sidekiq/web'

Rails.application.routes.draw do
  # Sidekiq Web UI (solo para admins)
  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  # Devise routes - Disabled registrations and password recovery for security
  # Only admins can create users through /admin/users
  devise_for :users, skip: [:registrations, :passwords]

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

    # Route management
    post 'start_route', to: 'dashboard#start_route', as: :start_route

    root 'dashboard#index'

    get 'communes/by_region/:region_id', to: 'communes#by_region', as: 'communes_by_region'
  end

  # Dashboard principal de customers (fuera del namespace)
  get 'customers', to: 'customers#index', as: :customers_dashboard

  # Redirect root según rol del usuario
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

  # Root por defecto (usuarios no autenticados van al login)
  root to: redirect('/users/sign_in')
  #Eso le devuelve un No Content (204) y Chrome queda feliz, y no aparece como error.
  get "/.well-known/appspecific/com.chrome.devtools.json", to: proc { [204, {}, []] }

end