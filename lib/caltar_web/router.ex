defmodule CaltarWeb.Router do
  use CaltarWeb, :router

  import Phoenix.LiveView.Router

  pipeline(:browser) do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {CaltarWeb.Components.Layouts, :root})
    plug(:put_layout, {CaltarWeb.Components.Layouts, :app})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  scope("/", CaltarWeb) do
    pipe_through([:browser])

    live_session :default, on_mount: [CaltarWeb.Hooks.PutLocale] do
      live("/", Main.Live)
    end
  end
end
