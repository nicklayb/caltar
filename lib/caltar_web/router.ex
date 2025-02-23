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

    live_session :settings,
      layout: {CaltarWeb.Components.Layouts, :settings},
      on_mount: [CaltarWeb.Hooks.PutLocale] do
      live("/settings", Settings.Global)
      live("/settings/calendars/:slug", Settings.Calendar)
    end

    live_session :default,
      layout: {CaltarWeb.Components.Layouts, :app},
      on_mount: [CaltarWeb.Hooks.PutLocale] do
      live("/", Calendar.Live)
      live("/:slug", Calendar.Live)
    end
  end
end
