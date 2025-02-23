defmodule CaltarWeb.Settings.Calendar do
  alias Caltar.Repo
  alias Caltar.Storage
  alias Caltar.Storage.Calendar
  alias CaltarWeb.Settings.Calendar.Provider, as: CalendarProvider
  use CaltarWeb, :live_view

  def mount(%{"slug" => slug}, _session, socket) do
    socket =
      socket
      |> assign(:page_key, {:calendar, slug})
      |> assign(:expanded, MapSet.new())
      |> load_calendar(slug)

    {:ok, socket}
  end

  defp load_calendar(socket, slug) do
    calendar =
      case Storage.get_calendar_by_slug(slug) do
        {:ok, %Calendar{} = calendar} ->
          Repo.preload(calendar, [:providers])

        _ ->
          nil
      end

    assign(socket, :calendar, calendar)
  end

  def handle_event("calendar:expand", %{"id" => id}, socket) do
    socket = update(socket, :expanded, &Box.MapSet.toggle(&1, id))

    {:noreply, socket}
  end
end
