defmodule Caltar.Calendar.Provider.Icalendar do
  use Caltar.Calendar.Provider
  use Caltar.Http
  alias Caltar.Storage.Provider

  alias Caltar.Calendar.Event
  alias Caltar.Calendar.Provider.Icalendar.Params, as: IcalendarParams
  alias Caltar.Calendar.Provider.Icalendar.Formula1Params
  alias Caltar.Storage.Configuration.Formula1
  alias Caltar.Storage.Configuration.Icalendar

  @impl Caltar.Calendar.Provider
  def poll(%DateTime{} = date_time, _old_state, %Provider{configuration: configuration}) do
    url = get_url(configuration)

    with {:ok, %HttpResponse{body: body}} <- get(url) do
      body
      |> ICalendar.from_ics()
      |> filter_interested_events(date_time)
      |> Box.Result.succeed()
    end
  end

  defp filter_interested_events(events, %DateTime{} = date_time) do
    two_months_after = Caltar.Date.shift(date_time, month: 2)

    events
    |> Stream.flat_map(fn
      %ICalendar.Event{rrule: %{} = rrule} = event ->
        end_date = Box.Map.get_with_default(rrule, :until, two_months_after)
        ICalendar.Recurrence.get_recurrences(event, end_date)

      event ->
        [event]
    end)
    |> Stream.filter(fn
      %ICalendar.Event{dtstart: %DateTime{} = start_time} ->
        Caltar.Date.same_month?(date_time, start_time)

      _ ->
        false
    end)
    |> Enum.to_list()
  end

  @impl Caltar.Calendar.Provider
  def update(state, state, _options), do: :nothing

  def update(_old_state, new_state, options) do
    events = Enum.map(new_state, &to_event(&1, options))

    new_state
    |> update_state()
    |> with_events(events)
  end

  defp to_event(%ICalendar.Event{} = event, %Provider{configuration: configuration}) do
    end_date = get_end_date_for_full_day_event(event)
    [start_date, end_date] = Enum.map([event.dtstart, end_date], &Caltar.Date.shift_timezone!/1)

    params = build_params(event, configuration)

    %Event{
      id: event.uid,
      starts_at: start_date,
      ends_at: end_date,
      title: event.summary,
      params: params
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

  defp build_params(%ICalendar.Event{}, %Icalendar{icon: icon}) do
    %IcalendarParams{icon: icon}
  end

  defp build_params(%ICalendar.Event{} = event, %Formula1{}) do
    Formula1Params.build(event)
  end

  defp get_url(%Icalendar{url: url}), do: url
  defp get_url(%Formula1{url: url}), do: url
end
