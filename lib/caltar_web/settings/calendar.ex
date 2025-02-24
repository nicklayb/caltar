defmodule CaltarWeb.Settings.Calendar do
  use CaltarWeb, :live_view

  alias Caltar.Repo
  alias Caltar.Storage
  alias Caltar.Storage.Calendar
  alias CaltarWeb.Settings.Calendar.Provider, as: CalendarProvider

  def mount(%{"slug" => slug}, _session, socket) do
    socket =
      socket
      |> assign(:slug, slug)
      |> assign(:page_key, {:calendar, slug})
      |> assign(:expanded, MapSet.new())
      |> assign_async([:calendar], fn -> load_calendar(slug) end)
      |> subscribe("calendar:#{slug}")

    {:ok, socket}
  end

  defp load_calendar(slug) do
    with {:ok, %Calendar{} = calendar} <- Storage.get_calendar_by_slug(slug) do
      {:ok, %{calendar: Repo.preload(calendar, [:providers])}}
    end
  end

  def handle_event("calendar:provider:expand", %{"id" => id}, socket) do
    socket = update(socket, :expanded, &Box.MapSet.toggle(&1, id))

    {:noreply, socket}
  end

  def handle_event("calendar:provider:new", _, socket) do
    socket =
      assign(
        socket,
        :modal,
        {CaltarWeb.Settings.Calendar.CreateProvider,
         calendar_id: socket.assigns.calendar.result.id}
      )

    {:noreply, socket}
  end

  def handle_pubsub(%Box.PubSub.Message{message: :calendar_updated}, socket) do
    socket =
      update_async_result(socket, :calendar, &Repo.preload(&1, [:providers], force: true))

    {:noreply, socket}
  end
end
