defmodule CaltarWeb.Settings.Global do
  alias Caltar.Storage
  alias Caltar.Storage.Calendar
  use CaltarWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, :page_key, :settings)
    {:ok, socket}
  end
end
