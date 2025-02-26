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

  def handle_event("calendar:provider:delete", %{"id" => id}, socket) do
    socket =
      case execute_use_case(socket, Caltar.Storage.UseCase.DeleteProvider, %{provider_id: id}) do
        {:ok, _} ->
          send(self(), :close_modal)
          socket

        _ ->
          socket
      end

    {:noreply, socket}
  end

  def handle_event("calendar:provider:edit", %{"id" => id}, socket) do
    socket =
      assign(
        socket,
        :modal,
        {CaltarWeb.Settings.Calendar.CreateOrUpdateProvider,
         calendar_id: socket.assigns.calendar.result.id, provider_id: id}
      )

    {:noreply, socket}
  end

  def handle_event("calendar:provider:new", _, socket) do
    socket =
      assign(
        socket,
        :modal,
        {CaltarWeb.Settings.Calendar.CreateOrUpdateProvider,
         calendar_id: socket.assigns.calendar.result.id}
      )

    {:noreply, socket}
  end

  @provider_updated_messages ~w(
    provider_updated
    provider_created
    provider_deleted
  )a
  def handle_pubsub(%Box.PubSub.Message{message: provider_updated_message}, socket)
      when provider_updated_message in @provider_updated_messages do
    socket =
      update_async_result(socket, :calendar, &Repo.preload(&1, [:providers], force: true))

    {:noreply, socket}
  end

  def handle_pubsub(%Box.PubSub.Message{message: :updated}, socket) do
    {:noreply, socket}
  end
end
