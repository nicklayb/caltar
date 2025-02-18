defmodule Caltar.Calendar do
  alias Caltar.Calendar.Builder, as: CalendarBuilder
  alias Caltar.Calendar.Event, as: CalendarEvent
  alias Caltar.Calendar

  defstruct [:start_date, :end_date, :current_time, :dates, events: %{}, markers: %{}]

  def build(date_time) do
    %{days: days, start_date: start_date, end_date: end_date} =
      CalendarBuilder.build_month(date_time)

    %Calendar{dates: days, start_date: start_date, end_date: end_date, current_time: date_time}
  end

  def events_for_date(%Calendar{events: events}, date) do
    events
    |> Map.get(date, [])
    |> Enum.sort(Calendar.Event)
  end

  def put_events(%Calendar{} = calendar, events) do
    Enum.reduce(events, calendar, fn event, acc ->
      case put_event(acc, event) do
        {:ok, acc} -> acc
        _ -> acc
      end
    end)
  end

  def reject_events(%Calendar{} = calendar, function) do
    map_all_events(calendar, fn date, events ->
      Enum.reject(events, fn event -> function.(date, event) end)
    end)
  end

  def put_event(%Calendar{} = calendar, %CalendarEvent{} = event) do
    if in_calendar?(calendar, event) do
      accumulator = remove_old_events(calendar, event)

      event
      |> CalendarEvent.to_occurences()
      |> Enum.reduce(accumulator, fn {date, event}, acc ->
        map_events(acc, date, fn _date, events ->
          [event | events]
        end)
      end)
      |> Box.Result.succeed()
    else
      {:error, :not_in_calendar}
    end
  end

  defp remove_old_events(%Calendar{events: events} = calendar, %CalendarEvent{id: id}) do
    new_events =
      Enum.reduce(events, %{}, fn {key, events}, acc ->
        updated_events = Enum.reject(events, &(&1.id == id))
        Map.put(acc, key, updated_events)
      end)

    %Calendar{calendar | events: new_events}
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

  defp in_calendar?(%Calendar{start_date: calendar_start, end_date: calendar_end}, %CalendarEvent{
         starts_at: starts_at,
         ends_at: ends_at
       }) do
    event_start = DateTime.to_date(starts_at)
    event_end = DateTime.to_date(ends_at)

    Date.after?(event_start, calendar_start) and
      Date.before?(event_end, calendar_end)
  end

  defp map_events(%Calendar{} = calendar, date, function) do
    map_events(calendar, fn events ->
      previous_events = Map.get(events, date, [])

      Map.put(events, date, function.(date, previous_events))
    end)
  end

  defp map_events(%Calendar{events: events} = calendar, function) do
    %Calendar{calendar | events: function.(events)}
  end

  defp map_all_events(%Calendar{} = calendar, function) do
    map_events(calendar, fn events ->
      Enum.reduce(events, %{}, fn {date, events}, acc ->
        updated = function.(date, events)
        Map.put(acc, date, updated)
      end)
    end)
  end
end
