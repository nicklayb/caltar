defmodule Caltar.Calendar.Provider.SportEvent do
  @behaviour Caltar.Calendar.Provider

  alias Caltar.Calendar.Provider.Sport.TheScore
  alias Caltar.Storage.Configuration.Sport
  alias Caltar.Calendar.Provider.Sport.EventParams
  alias Caltar.Calendar.Event
  alias Caltar.Storage.Provider

  @minute 60
  @start_in_threshold 15
  @impl Caltar.Calendar.Provider
  def poll(
        %DateTime{},
        _old_state,
        {%Event{params: %EventParams{id: id}}, %Provider{configuration: %Sport{} = sport}}
      ) do
    with {:ok, event} <- request_event(sport.provider, sport.sport, sport.team_id, id) do
      {:ok, [event]}
    end
  end

  @impl Caltar.Calendar.Provider
  def update(state, state, _options), do: :nothing

  def update(_old_state, [%Event{starts_at: starts_at} = event], _options) do
    now = Caltar.Date.now!()
    event_in = DateTime.diff(now, starts_at, :minute)
    starts_soon? = event_in <= @start_in_threshold
    status = event.params.progress.status

    every =
      cond do
        status == :in_progress -> @minute
        status == :pending and starts_soon? -> @minute
        status == :pending -> @minute * 10
        true -> @minute * 30
      end

    if not Caltar.Date.same_day?(now, starts_at) do
      send(self(), :stop)
    end

    {:update, [event], [event], [every: every]}
  end

  def request_event("thescore", sport, team_id, event_id) do
    TheScore.event(sport: sport, team_id: team_id, event_id: event_id)
  end
end
