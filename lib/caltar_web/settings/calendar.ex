defmodule CaltarWeb.Settings.Calendar do
  alias Caltar.Storage
  alias Caltar.Storage.Calendar
  use CaltarWeb, :live_view

  def mount(%{"slug" => slug}, _session, socket) do
    socket = assign(socket, :page_key, {:calendar, slug})

    {:ok, socket}
  end
end
