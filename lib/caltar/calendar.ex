defmodule Caltar.Calendar do
  alias Caltar.Calendar.Builder, as: CalendarBuilder
  alias Caltar.Calendar.Event, as: CalendarEvent
  alias Caltar.Calendar
  defstruct [:start_date, :end_date, :dates, events: %{}]

  def build(date) do
    %{days: days, start_date: start_date, end_date: end_date} = CalendarBuilder.build_month(date)

    %Calendar{dates: days, start_date: start_date, end_date: end_date}
  end

  def put_event(%Calendar{} = calendar, %CalendarEvent{} = event) do
    if in_calendar?(calendar, event) do
      event
      |> CalendarEvent.to_occurences()
      |> Enum.reduce(calendar, fn {date, event}, acc ->
        map_events(acc, date, fn _date, events ->
          [event | events]
        end)
      end)
    else
      {:error, :not_in_calendar}
    end
  end

  defp in_calendar?(%Calendar{start_date: start_date, end_date: end_date}, %CalendarEvent{
         starts_at: starts_at,
         ends_at: ends_at
       }) do
    Date.after?(start_date, starts_at) and Date.before?(end_date, ends_at)
  end

  defp map_events(%Calendar{events: events} = calendar, date, function) do
    previous_events = Map.get(events, date, [])

    updated_events = function.(date, previous_events)

    %Calendar{calendar | events: updated_events}
  end
end
