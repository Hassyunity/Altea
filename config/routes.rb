Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Everything lives inside a life area: /work/... or /personal/...
  scope ":life_area", constraints: { life_area: /work|personal/ } do
    get "/", to: "dashboards#show", as: :dashboard

    resources :projects
    resources :tasks do
      patch :toggle, on: :member
    end
    resources :notes do
      patch :pin, on: :member
    end
  end

  root to: redirect("/work")
end
