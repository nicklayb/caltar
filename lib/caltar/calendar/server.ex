defmodule Caltar.Calendar.Server do
  alias Caltar.Calendar
  alias Caltar.Calendar.Server, as: CalendarServer
  use GenServer

  defstruct [:args, :calendar]

  @name Caltar.Calendar.Server
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: Keyword.get(args, :name, @name))
  end

  def init(args) do
    {:ok, init_state(args)}
  end

  def get_calendar(name \\ @name) do
    GenServer.call(name, :get_calendar)
  end

  def reset(name \\ @name) do
    GenServer.cast(name, :reset)
  end

  def handle_cast(:reset, state) do
    {:noreply, reset_state(state)}
  end

  def handle_call(:get_calendar, _, %{calendar: calendar} = state) do
    {:reply, calendar, state}
  end

  def handle_info(
        %Box.PubSub.Message{topic: "calendar", message: :updated, params: {provider, events}},
        state
      ) do
    state =
      map_calendar(state, fn calendar ->
        calendar
        |> Calendar.reject_events(fn _date, event -> event.provider == provider end)
        |> Calendar.put_events(events)
      end)

    {:noreply, state}
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

    calendar =
      Calendar.put_events(calendar, [
        Caltar.Factory.build(:calendar_event,
          title: "Show de musique de pwell de punk de tassez vous les cassé",
          starts_at: DateTime.new!(~D[2025-02-21], ~T[09:30:00], "America/Montreal"),
          ends_at: DateTime.new!(~D[2025-02-22], ~T[15:00:00], "America/Montreal")
        ),
        Caltar.Factory.build(:calendar_event,
          title: "Show de musique",
          starts_at: DateTime.new!(~D[2025-02-21], ~T[09:30:00], "America/Montreal"),
          ends_at: DateTime.new!(~D[2025-02-22], ~T[15:00:00], "America/Montreal")
        ),
        Caltar.Factory.build(:calendar_event,
          title: "Show de musique",
          starts_at: DateTime.new!(~D[2025-02-21], ~T[13:10:00], "America/Montreal"),
          ends_at: DateTime.new!(~D[2025-02-21], ~T[16:30:00], "America/Montreal")
        ),
        Caltar.Factory.build(:calendar_event,
          title: "Show de musique",
          starts_at: DateTime.new!(~D[2025-02-21], ~T[08:30:00], "America/Montreal"),
          ends_at: DateTime.new!(~D[2025-02-21], ~T[10:30:00], "America/Montreal")
        ),
        Caltar.Factory.build(:calendar_event,
          title: "Show de musique",
          starts_at: DateTime.new!(~D[2025-02-21], ~T[20:30:00], "America/Montreal"),
          ends_at: DateTime.new!(~D[2025-02-21], ~T[23:30:00], "America/Montreal")
        )
      ])

    state = %CalendarServer{args: args, calendar: calendar}

    send_update(state)
  end

  defp reset_state(%CalendarServer{args: args}) do
    init_state(args)
  end
end
