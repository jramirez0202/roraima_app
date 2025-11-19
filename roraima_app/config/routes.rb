Rails.application.routes.draw do
  devise_for :users

  # Admin namespace
  namespace :admin do
    resources :users
    resources :packages
    root 'packages#index'
    get 'communes/by_region/:region_id', to: 'communes#by_region', as: 'communes_by_region'
  end

  # Customers namespace
  namespace :customers do
    resources :packages do
      member do
        patch :cancel
      end
    end
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