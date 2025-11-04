Rails::Assessment::Engine.routes.draw do
  resources :assessments, only: [ :show ], param: :slug, path: "/" do
    get :result, on: :member
    resource :response, only: :create, controller: "responses"
  end
end
