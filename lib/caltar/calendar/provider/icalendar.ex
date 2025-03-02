defmodule Caltar.Calendar.Provider.Icalendar do
  @behaviour Caltar.Calendar.Provider
  alias Caltar.Storage.Provider
  use Caltar.Http

  alias Caltar.Calendar.Event
  alias Caltar.Storage.Configuration.Icalendar

  @impl Caltar.Calendar.Provider
  def poll(%DateTime{} = date_time, _old_state, %Provider{configuration: %Icalendar{url: url}}) do
    with {:ok, %HttpResponse{body: body}} <- get(url) do
      body
      |> ICalendar.from_ics()
      |> filter_interested_events(date_time)
      |> Box.Result.succeed()
    end
  end

  defp filter_interested_events(events, %DateTime{} = date_time) do
    Enum.filter(events, fn
      %ICalendar.Event{dtstart: %DateTime{} = start_time} ->
        Caltar.Date.same_month?(date_time, start_time)

      _ ->
        false
    end)
  end

  @impl Caltar.Calendar.Provider
  def update(state, state, _options), do: :nothing

  def update(_old_state, new_state, _options) do
    events = Enum.map(new_state, &to_event/1)
    {:update, new_state, events}
  end

  defp to_event(%ICalendar.Event{} = event) do
    end_date = get_end_date_for_full_day_event(event)
    [start_date, end_date] = Enum.map([event.dtstart, end_date], &Caltar.Date.shift_timezone!/1)

    %Event{
      id: event.uid,
      starts_at: start_date,
      ends_at: end_date,
      title: event.summary
    }
  end

  defp get_end_date_for_full_day_event(%ICalendar.Event{dtstart: start_date, dtend: end_date}) do
    if Caltar.Date.start_of_day?(start_date) and Caltar.Date.start_of_day?(end_date) and
         abs(DateTime.diff(start_date, end_date, :day)) == 1 do
      start_date
    else
      end_date
    end
  end
end
