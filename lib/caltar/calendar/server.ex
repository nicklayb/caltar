defmodule Caltar.Calendar.Server do
  use GenServer

  alias Caltar.Calendar.StorageSupervisor
  alias Caltar.Calendar
  alias Caltar.Calendar.Event
  alias Caltar.Calendar.Marker
  alias Caltar.Calendar.Server, as: CalendarServer

  require Logger

  defstruct [:id, :slug, :args, :calendar]

  @name Caltar.Calendar.Server
  def start_link(args) do
    slug = Keyword.fetch!(args, :slug)
    id = Keyword.fetch!(args, :id)
    name = StorageSupervisor.registry_name({CalendarServer, id, slug})
    GenServer.start_link(__MODULE__, args, name: name)
  end

  def init(args) do
    {:ok, init_state(args)}
  end

  def get_calendar(name \\ @name) do
    GenServer.call(name, :get_calendar)
  end

  def get_calendar_by_slug(slug) do
    slug
    |> Caltar.Calendar.StorageSupervisor.get_calendar_server()
    |> get_calendar()
  end

  def reset(name \\ @name) do
    GenServer.cast(name, :reset)
  end

  def handle_cast(:reset, state) do
    {:noreply, reset_state(state)}
  end

  def handle_cast({:updated, provider, events}, state) do
    log(:debug, state, "updating")

    state =
      map_calendar(state, fn calendar ->
        {markers, events} =
          Enum.split_with(events, fn
            %Marker{} -> true
            %Event{} -> false
          end)

        calendar
        |> Calendar.reject_events(fn _date, event -> event.provider == provider end)
        |> Calendar.put_events(events)
        |> Calendar.reject_markers(fn _date, marker -> marker.provider == provider end)
        |> Calendar.put_markers(markers)
      end)

    {:noreply, state}
  end

  def handle_call(:get_calendar, _, %{calendar: calendar} = state) do
    {:reply, calendar, state}
  end

  defp map_calendar(%CalendarServer{calendar: calendar} = state, function) do
    new_state = %CalendarServer{state | calendar: function.(calendar)}

    if updated?(state, new_state) do
      log(:debug, state, "updated")
      send_update(new_state)
    end

    new_state
  end

  defp send_update(%CalendarServer{slug: slug, calendar: calendar} = state) do
    Caltar.PubSub.broadcast("calendar:#{slug}", {:updated, calendar})
    state
  end

  defp updated?(%CalendarServer{calendar: %Calendar{markers: old_markers, events: old_events}}, %{
         calendar: %Calendar{markers: new_markers, events: new_events}
       }) do
    old_events != new_events or old_markers != new_markers
  end

  defp init_state(args) do
    calendar = Calendar.build(Caltar.Date.now!())
    slug = Keyword.fetch!(args, :slug)
    id = Keyword.fetch!(args, :id)

    state = %CalendarServer{id: id, args: args, slug: slug, calendar: calendar}

    send_update(state)
  end

  defp reset_state(%CalendarServer{args: args}) do
    init_state(args)
  end

  defp log(:debug, %CalendarServer{} = state, message) do
    state
    |> build_message(message)
    |> Logger.debug()
  end

  defp build_message(%CalendarServer{} = state, message) do
    "[#{inspect(__MODULE__)}] [#{inspect_provider(state)}] #{message}"
  end

  defp inspect_provider(%CalendarServer{slug: slug}), do: slug
end
