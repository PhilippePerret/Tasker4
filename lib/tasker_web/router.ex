defmodule TaskerWeb.Router do
  use TaskerWeb, :router

  import TaskerWeb.WorkerAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TaskerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_worker
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TaskerWeb do
    pipe_through :browser
    get "/", PageController, :home
  end

  scope "/work", TaskerWeb do
    pipe_through [:browser, :require_authenticated_worker]
    get "/", OneTaskCycleController, :main
  end

  scope "/tools", TaskerWeb do
    pipe_through [:browser, :require_authenticated_worker]
    post "/:script", ToolsController, :run_script
  end

  scope "/tasksop", TaskerWeb do
    pipe_through [:browser, :require_authenticated_worker]
    post "/:op", TasksOpController, :exec_operation
  end

  # Other scopes may use custom stacks.
  # scope "/api", TaskerWeb do
  #   pipe_through :api
  # end

  # Enable Swoosh mailbox preview in development
  if Application.compile_env(:tasker, :dev_routes) do

    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", TaskerWeb do
    pipe_through [:browser, :redirect_if_worker_is_authenticated]

    get "/workers/register", WorkerRegistrationController, :new
    post "/workers/register", WorkerRegistrationController, :create
    get "/workers/log_in", WorkerSessionController, :new
    post "/workers/log_in", WorkerSessionController, :create
    get "/workers/reset_password", WorkerResetPasswordController, :new
    post "/workers/reset_password", WorkerResetPasswordController, :create
    get "/workers/reset_password/:token", WorkerResetPasswordController, :edit
    put "/workers/reset_password/:token", WorkerResetPasswordController, :update
  end

  scope "/", TaskerWeb do
    pipe_through [:browser, :require_authenticated_worker]

    get "/workers/settings", WorkerSettingsController, :edit
    put "/workers/settings", WorkerSettingsController, :update
    get "/workers/settings/confirm_email/:token", WorkerSettingsController, :confirm_email
  end
  
  scope "/", TaskerWeb do
    pipe_through [:browser]
    
    delete "/workers/log_out", WorkerSessionController, :delete
    get "/workers/confirm", WorkerConfirmationController, :new
    post "/workers/confirm", WorkerConfirmationController, :create
    get "/workers/confirm/:token", WorkerConfirmationController, :edit
    post "/workers/confirm/:token", WorkerConfirmationController, :update
    
    # Pour la gestion des workers
    resources "/workers", WorkerController
  end
  
  scope "/", TaskerWeb do
    pipe_through [:browser, :require_authenticated_worker]
        
    # Pour la gestion des tâches (Tache.Task)
    resources "/tasks", TaskController
    # Pour la gestion des projets
    resources "/projects", ProjectController
  end
end
