defmodule CaltarWeb do
  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: CaltarWeb.Layouts]

      import Plug.Conn

      unquote(view_helpers())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: CaltarWeb.Endpoint,
        router: CaltarWeb.Router,
        statics: CaltarWeb.static_paths()
    end
  end

  def component do
    quote do
      use Phoenix.Component

      unquote(view_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView
      require Logger
      import CaltarWeb.PubSub

      on_mount(CaltarWeb.Hooks.PubSubInterceptor)

      @before_compile {CaltarWeb, :live_view_before_compile}

      unquote(view_helpers())
    end
  end

  def view_helpers do
    quote do
      use Gettext, backend: CaltarWeb.Gettext
      import CaltarWeb.Live
      alias CaltarWeb.Html
      alias CaltarWeb.Components
      unquote(verified_routes())
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  defmacro live_view_before_compile(_) do
    quote do
      def handle_pubsub(message, socket) do
        Logger.warning("#{socket.view} unhandled pub sub #{inspect(message)}")
        {:noreply, socket}
      end
    end
  end
end
