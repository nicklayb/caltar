defmodule Caltar.Calendar do
  alias Caltar.Calendar
  alias Caltar.Calendar.Event, as: CalendarEvent
  alias Caltar.Calendar.Marker, as: CalendarMarker

  defstruct [:start_date, :end_date, :current_time, :mode, dates: [], events: %{}, markers: %{}]

  def rebuild(%Calendar{} = calendar, date_time) do
    new_calendar = build(date_time, calendar.mode)

    %Calendar{
      calendar
      | start_date: new_calendar.start_date,
        current_time: new_calendar.current_time,
        end_date: new_calendar.end_date,
        dates: new_calendar
    }
  end

  def build(date_time, mode \\ :current_month) do
    {start_date, end_date} =
      date_time
      |> Caltar.Date.to_date()
      |> mode_range(mode)

    build_dates(%Calendar{
      mode: mode,
      current_time: date_time,
      start_date: start_date,
      end_date: end_date
    })
  end

  def build_dates(%Calendar{start_date: start_date, end_date: end_date} = calendar) do
    dates =
      start_date
      |> build_dates(end_date, [])
      |> Enum.reverse()
      |> Enum.chunk_every(Caltar.Date.days_in_week())

    %Calendar{calendar | dates: dates}
  end

  def build_dates(current_date, end_date, acc) do
    new_acc = [current_date | acc]

    if Date.compare(current_date, end_date) == :eq do
      new_acc
    else
      current_date
      |> Caltar.Date.shift(day: 1)
      |> build_dates(end_date, new_acc)
    end
  end

  defp mode_range(date_time, :current_month) do
    start_date =
      date_time
      |> Caltar.Date.start_of_month()
      |> Caltar.Date.start_of_week()

    end_date =
      date_time
      |> Caltar.Date.end_of_month()
      |> Caltar.Date.end_of_week()

    {start_date, end_date}
  end

  defp mode_range(date_time, {:relative, weeks_before, weeks_after}) do
    start_date =
      date_time
      |> Caltar.Date.shift(week: -weeks_before)
      |> Caltar.Date.start_of_week()

    end_date =
      date_time
      |> Caltar.Date.shift(week: weeks_after)
      |> Caltar.Date.end_of_week()

    {start_date, end_date}
  end

  defp mode_range(date_time, {:relative, week_count}) do
    mode_range(date_time, {:relative, week_count, week_count})
  end

  def events_for_date(%Calendar{events: events}, date) do
    events
    |> Map.get(date, [])
    |> Enum.sort(Calendar.Event)
  end

  def markers_for_date(%Calendar{markers: markers}, date) do
    Map.get(markers, date, [])
  end

  def put_events(%Calendar{} = calendar, events) do
    Enum.reduce(events, calendar, fn event, acc ->
      case put_event(acc, event) do
        {:ok, acc} -> acc
        _ -> acc
      end
    end)
  end

  def put_markers(%Calendar{} = calendar, markers) do
    Enum.reduce(markers, calendar, fn marker, acc ->
      case put_marker(acc, marker) do
        {:ok, acc} -> acc
        _ -> acc
      end
    end)
  end

  def reject_markers(%Calendar{} = calendar, function) do
    map_all_markers(calendar, fn date, markers ->
      Enum.reject(markers, fn marker -> function.(date, marker) end)
    end)
  end

  def reject_events(%Calendar{} = calendar, function) do
    map_all_events(calendar, fn date, events ->
      Enum.reject(events, fn event -> function.(date, event) end)
    end)
  end

  def put_marker(%Calendar{} = calendar, %CalendarMarker{} = marker) do
    if in_calendar?(calendar, marker) do
      accumulator = remove_old_markers(calendar, marker)

      accumulator
      |> map_markers(marker.date, fn _date, markers ->
        [marker | markers]
      end)
      |> Box.Result.succeed()
    else
      {:error, :not_in_calendar}
    end
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

  defp remove_old_markers(%Calendar{markers: markers} = calendar, %CalendarMarker{id: id}) do
    new_markers =
      Enum.reduce(markers, %{}, fn {key, markers}, acc ->
        updated_markers = Enum.reject(markers, &(&1.id == id))
        Map.put(acc, key, updated_markers)
      end)

    %Calendar{calendar | markers: new_markers}
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

  defp in_calendar?(
         %Calendar{start_date: calendar_start, end_date: calendar_end},
         %CalendarMarker{date: date}
       ) do
    Date.after?(date, calendar_start) and Date.before?(date, calendar_end)
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

  defp map_markers(%Calendar{} = calendar, date, function) do
    map_markers(calendar, fn markers ->
      previous_markers = Map.get(markers, date, [])

      Map.put(markers, date, function.(date, previous_markers))
    end)
  end

  defp map_markers(%Calendar{markers: markers} = calendar, function) do
    %Calendar{calendar | markers: function.(markers)}
  end

  defp map_all_markers(%Calendar{} = calendar, function) do
    map_markers(calendar, fn markers ->
      Enum.reduce(markers, %{}, fn {date, markers}, acc ->
        updated = function.(date, markers)
        Map.put(acc, date, updated)
      end)
    end)
  end
end
