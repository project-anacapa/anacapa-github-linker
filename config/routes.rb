Rails.application.routes.draw do
  resources :schools
  # resources :roster_students
  # devise routes
  devise_for :users, :controllers => {
      :omniauth_callbacks => "users/omniauth_callbacks#github"
  }
  devise_scope :user do
    get 'sign_out', :to => 'devise/sessions#destroy', :as => :signout
  end

  constraints CanAccessFlipperUI do
    mount Flipper::UI.app(Flipper) => '/admin/flipper'
  end

  namespace :api, :defaults => { :format => 'json' } do

    match 'testhooks/login_student' => 'testhooks#login_student', :via => :get
    match 'testhooks/login_admin' => 'testhooks#login_admin', :via => :get

    resources :visitors

    resources :courses do
      post :graphql
      scope module: :courses do
        resources :project_teams
        resources :org_teams
        resources :github_repos do
          resources :repo_commit_events
        end
        resources :roster_students do
          get :activity
          get :commits
          get :issues
          get :pull_requests
        end
      end
    end

    resources :schools
  end

  # courses routes
  # post 'courses/:course_id/join' => 'courses#join', :as => :join_course
  # post 'courses/:course_id/leave' => 'courses#leave', :as => :leave_course
  resources :courses do
    post :join
    get :jobs
    get :repos
    get :search_repos
    get :events
    get :commits
    get :issues
    post :run_course_job
    post :update_ta
    get :create_repos
    post :generate_repos
    get :project_repos
    scope module: :courses do

      resources :roster_students do
        collection do
          post :import
        end
        get :activity
      end
      resources :informed_consents do
        collection do
          post :import
        end
      end
      resources :github_repos do
        collection do
          get :external
        end
        resources :repo_commit_events
        resources :repo_issue_events
        post :run_job
      end

      resources :org_teams do
        collection do
          get :create_repos
          post :generate_repos
          get :create_teams
          post :generate_teams
          get :unadded
        end
      end

      get "project_teams(/*all)", to: "project_teams#index", as: :project_teams
      resource :github_webhooks, :only => [:create], :defaults => {:format => :json} do
        # empty block
      end
      # While this is somewhat frowned upon in Rails convention, I refuse to name the controller "SlacksController"
      resource :slack, :controller => 'slack'

    end # scope module: :courses
  end

  namespace :slack, path: 'slack' do
    resource :auth, :controller => 'auth', :only => [] do
      get :callback
    end
    resource :commands, :only => [] do
      post :whois
    end
  end

  resources :users

  # Admin management dashboard
  resource :admin, :controller => 'admin', :only => [] do
    get :dashboard
    post :run_admin_job
  end

  # home page routes
  resources :visitors # NOTE that this defines a number of unused routes that would be good to remove for security
  root :to => "visitors#index"
end
