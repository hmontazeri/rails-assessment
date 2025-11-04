Rails::Assessment::Engine.routes.draw do
  resources :assessments, only: [ :show ], param: :slug, path: "/" do
    get "result/:response_uuid", action: :result, as: :result
    resource :response, only: :create, controller: "responses"
  end
end
