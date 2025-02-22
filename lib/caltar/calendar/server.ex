defmodule Caltar.Calendar.Server do
  alias Caltar.Calendar.Marker
  alias Caltar.Calendar.Event
  alias Caltar.Calendar
  alias Caltar.Calendar.Server, as: CalendarServer
  use GenServer

  defstruct [:args, :calendar]

  @name Caltar.Calendar.Server
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
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
      send_update(new_state)
    end

    new_state
  end

  defp send_update(%CalendarServer{calendar: calendar} = state) do
    Caltar.PubSub.broadcast("calendar", {:updated, calendar})
    state
  end

  defp updated?(%CalendarServer{calendar: %Calendar{events: old_events}}, %{
         calendar: %Calendar{events: new_events}
       }) do
    old_events != new_events
  end

  defp init_state(args) do
    calendar = Calendar.build(Caltar.Date.now!())

    state = %CalendarServer{args: args, calendar: calendar}

    send_update(state)
  end

  defp reset_state(%CalendarServer{args: args}) do
    init_state(args)
  end
end
