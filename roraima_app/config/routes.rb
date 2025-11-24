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
    resources :packages do
      collection do
        post :generate_labels
      end
      member do
        patch :change_status
        patch :assign_courier
        get :status_history
      end
    end
    resources :bulk_uploads, only: [:new, :create, :show]
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

  # Dashboard principal de customers (fuera del namespace)
  get 'customers', to: 'customers#index', as: :customers_dashboard

  # Redirect root según rol del usuario
  authenticated :user do
    root to: redirect { |params, request|
      user = request.env['warden'].user
      user.admin? ? '/admin' : '/customers'
    }, as: :authenticated_root
  end

  # Root por defecto (usuarios no autenticados van al login)
  root to: redirect('/users/sign_in')
end