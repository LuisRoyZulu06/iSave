defmodule IsaveWeb.Router do
  use IsaveWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_layout, {IsaveWeb.LayoutView, :app}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug(IsaveWeb.Plugs.SetUser)
  end

  pipeline :session do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:put_secure_browser_headers)
    plug(:put_root_layout, {IsaveWeb.LayoutView, :login})
  end

  pipeline :no_layout do
    plug :put_layout, false
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # ------------- NO LAYOUT SCOPE
  scope "/", IsaveWeb do
    pipe_through([:browser, :no_layout])
    get("/logout/current/user", SessionController, :signout)
  end

  # ------------- SESSION SCOPE
  scope "/", IsaveWeb do
    pipe_through :session
    get("/", SessionController, :new)
    post("/login", SessionController, :create)
    get("/forgort/password", UserController, :forgot_password)
    post("/confirmation/token", UserController, :token)
    get("/reset/password", UserController, :default_password)
  end

  # ------------- APP SCOPE
  scope "/", IsaveWeb do
    pipe_through :browser
    # ---------------- user CONTROLLER
    get("/dashboard", UserController, :dashboard)
    get("/user/management", UserController, :user_mgt)
    post("/get/active/user", UserController, :get_user_mgt)
    post("/get/blocked/user", UserController, :get_blckd_user)
    post("/create/new/user", UserController, :create_user)

    # ---------------- payroll CONTROLLER
    get("/payroll", PayrollController, :index)
  end

  # scope "/", IsaveWeb do
  #   pipe_through :browser
  #
  #   get "/", PageController, :index
  # end

  # Other scopes may use custom stacks.
  # scope "/api", IsaveWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: IsaveWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
