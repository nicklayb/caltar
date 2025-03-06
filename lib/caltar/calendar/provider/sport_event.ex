defmodule Caltar.Calendar.Provider.SportEvent do
  use Caltar.Calendar.Provider

  alias Caltar.Calendar.Event
  alias Caltar.Calendar.Provider.Sport.EventParams
  alias Caltar.Calendar.Provider.Sport.HockeyTech
  alias Caltar.Calendar.Provider.Sport.TheScore
  alias Caltar.Storage.Configuration.Sport
  alias Caltar.Storage.Provider

  @minute 60
  @start_in_threshold 15
  @impl Caltar.Calendar.Provider
  def poll(
        %DateTime{},
        _old_state,
        {%Event{params: %EventParams{id: id}}, %Provider{configuration: %Sport{} = sport}}
      ) do
    with {:ok, %Event{starts_at: starts_at} = event} <-
           request_event(sport.provider, sport.sport, sport.team_id, id) do
      if Caltar.Date.same_day?(Caltar.Date.now!(), starts_at) do
        {:ok, [event]}
      else
        {:ok, []}
      end
    end
  end

  @impl Caltar.Calendar.Provider
  def update(_, [], _) do
    send(self(), :stop)

    []
    |> update_state()
    |> with_events([])
    |> reconfigure(:every, :never)
  end

  def update([last_event], [%Event{starts_at: starts_at} = event], _options) do
    event_in = DateTime.diff(starts_at, Caltar.Date.now!(), :minute)
    starts_soon? = event_in <= @start_in_threshold
    status = event.params.progress.status

    every =
      cond do
        status == :in_progress -> @minute
        status == :pending and starts_soon? -> @minute
        status == :pending -> @minute * 10
        true -> @minute * 30
      end

    [event]
    |> update_state()
    |> with_events(if last_event != event, do: [event], else: :no_update)
    |> reconfigure(:every, every)
  end

  def update(_, [event], _options) do
    [event]
    |> update_state()
    |> with_events([event])
  end

  def request_event("hockey_tech", sport, team_id, event_id) do
    HockeyTech.event(sport: sport, team_id: team_id, event_id: event_id)
  end

  def request_event("thescore", sport, team_id, event_id) do
    TheScore.event(sport: sport, team_id: team_id, event_id: event_id)
  end
end
