defmodule CaltarWeb.Settings.Calendar do
  alias Phoenix.LiveView.AsyncResult
  use CaltarWeb, :live_view

  alias Caltar.Repo
  alias Caltar.Storage
  alias Caltar.Storage.Calendar
  alias CaltarWeb.Components.Form
  alias CaltarWeb.Settings.Calendar.Provider, as: CalendarProvider
  alias CaltarWeb.Settings.Calendar.EditCalendarForm

  def mount(%{"slug" => slug}, _session, socket) do
    socket =
      socket
      |> assign(:slug, slug)
      |> assign(:page_key, {:calendar, slug})
      |> assign(:expanded, MapSet.new())
      |> assign(:base_types, [
        {gettext("Choose"), ""}
        | Enum.map(EditCalendarForm.base_types(), &{Html.titleize(&1), &1})
      ])
      |> assign(:calendar, AsyncResult.loading())
      |> start_async(:load_calendar, fn -> load_calendar(slug) end)
      |> subscribe("calendar:#{slug}")

    {:ok, socket}
  end

  defp assign_form(socket, params \\ %{})

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp assign_form(socket, params) do
    assign_form(socket, changeset(socket, params))
  end

  defp changeset(%{assigns: %{calendar: %AsyncResult{result: calendar}}}, params) do
    calendar
    |> EditCalendarForm.from_calendar()
    |> EditCalendarForm.changeset(params)
  end

  defp load_calendar(slug) do
    with {:ok, %Calendar{} = calendar} <- Storage.get_calendar_by_slug(slug) do
      Repo.preload(calendar, [:providers])
    end
  end

  def handle_async(:load_calendar, {:ok, calendar}, socket) do
    socket =
      socket
      |> assign(:calendar, AsyncResult.ok(calendar))
      |> assign_form()

    {:noreply, socket}
  end

  def handle_event("calendar:change", %{"edit_calendar_form" => params}, socket) do
    socket = assign_form(socket, params)
    {:noreply, socket}
  end

  def handle_event(
        "calendar:save",
        %{"edit_calendar_form" => params},
        %{assigns: %{calendar: %AsyncResult{result: calendar}}} = socket
      ) do
    socket = assign_form(socket, params)

    with {:ok, form} <- Ecto.Changeset.apply_action(socket.assigns.form.source, :insert),
         params <- EditCalendarForm.to_changeset_params(form, calendar),
         {:ok, calendar} <-
           execute_use_case(socket, Caltar.Storage.UseCase.UpdateCalendar, params) do
      socket =
        socket
        |> update_async_result(:calendar, fn _ -> Repo.preload(calendar, [:providers]) end)
        |> assign_form()

      {:noreply, socket}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        socket = assign_form(socket, changeset)
        {:noreply, socket}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("calendar:provider:expand", %{"id" => id}, socket) do
    socket = update(socket, :expanded, &Box.MapSet.toggle(&1, id))

    {:noreply, socket}
  end

  def handle_event("calendar:provider:refresh", %{"id" => id}, socket) do
    Caltar.Calendar.StorageSupervisor.refresh_poller(id)
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
