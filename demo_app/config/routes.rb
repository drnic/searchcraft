Rails.application.routes.draw do
  namespace :slow do
    resources :products, only: [:index]
  end
  namespace :searchcraft do
    resources :products, only: [:index]
  end

  root "searchcraft/products#index"
end
