Rails::Assessment::Engine.routes.draw do
  resources :assessments, only: [ :show ], param: :slug, path: "/" do
    resource :response, only: :create, controller: "responses"
  end

  get "/:slug/result/:response_uuid", to: "assessments#result", as: :assessment_result
end
