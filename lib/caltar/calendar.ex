defmodule Caltar.Calendar do
  alias Caltar.Calendar.Builder, as: CalendarBuilder
  alias Caltar.Calendar.Event, as: CalendarEvent
  alias Caltar.Calendar
  defstruct [:start_date, :end_date, :current_time, :dates, events: %{}]

  def build(date_time) do
    %{days: days, start_date: start_date, end_date: end_date} =
      CalendarBuilder.build_month(date_time)

    %Calendar{dates: days, start_date: start_date, end_date: end_date, current_time: date_time}
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

  def current_month?(%Calendar{current_time: current_time}, day) do
    Caltar.Date.same_month?(current_time, day)
  end

  def current_week?(%Calendar{} = calendar, week) do
    Enum.any?(week, &current_day?(calendar, &1))
  end

  def current_day?(%Calendar{current_time: current_time}, day) do
    Caltar.Date.same_day?(current_time, day)
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
