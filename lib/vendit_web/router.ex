defmodule VenditWeb.Router do
  use VenditWeb, :router

  import VenditWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_api_user
  end

  scope "/", VenditWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", VenditWeb do
  #   pipe_through :api

  #   post "/user", UserController, :new
  # end

  # scope "/api", VenditWeb do
  #   pipe_through [:api, :require_authenticated_user]

  #   get "/user/:id", UserController, :show
  #   patch "/user/:id", UserController, :edit
  #   delete "/user/:id", UserController, :delete
  # end

  ## Authentication routes
  scope "/", VenditWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{VenditWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", VenditWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_seller,
      on_mount: [
        {VenditWeb.UserAuth, :ensure_authenticated_seller}
      ] do
      live "/products/new", ProductLive.Index, :new
    end

    live_session :require_authenticated_user,
      on_mount: [{VenditWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
      live "/products", ProductLive.Index, :index
      live "/products/:id", ProductLive.Show, :show
      live "/app", VendingMachineLive, :new
    end

    live_session :require_authenticated_seller_owns_product,
      on_mount: [
        {VenditWeb.UserAuth, :ensure_authenticated_seller},
        {VenditWeb.UserAuth, :ensure_seller_owns_item}
      ] do
      live "/products/:id/edit", ProductLive.Index, :edit
      live "/products/:id/show/edit", ProductLive.Show, :edit
    end
  end

  scope "/", VenditWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{VenditWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end

  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through [:browser]

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
