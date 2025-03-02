defmodule Caltar.Calendar.Provider.SportSchedule do
  @behaviour Caltar.Calendar.Provider

  alias Caltar.Calendar.Provider.Sport.Supervisor, as: SportSupervisor
  alias Caltar.Calendar.Poller
  alias Caltar.Calendar.Event
  alias Caltar.Storage.Provider
  alias Caltar.Storage.Configuration.Sport
  alias Caltar.Calendar.Provider.Sport.TheScore

  @impl Caltar.Calendar.Provider
  def poll(
        %DateTime{} = current_time,
        _old_state,
        %Provider{configuration: %Sport{} = sport} = provider
      ) do
    with {:ok, sport_events} <- request_events(sport.provider, sport.sport, sport.team_id) do
      sport_events =
        current_time
        |> DateTime.to_date()
        |> start_current_pollers(sport_events, provider)

      {:ok, sport_events}
    end
  end

  defp start_current_pollers(%Date{} = today, sport_events, provider) do
    {current_events, other_events} =
      Enum.split_with(sport_events, fn %Event{starts_at: starts_at} ->
        Caltar.Date.same_day?(starts_at, today)
      end)

    Enum.each(current_events, fn current_event ->
      SportSupervisor.start_child(
        provider.id,
        {Poller,
         id: provider.id <> ":" <> to_string(current_event.id),
         color: provider.color,
         every: 60,
         calendar_id: provider.calendar_id,
         module: Caltar.Calendar.Provider.SportEvent,
         options: {current_event, provider}}
      )
    end)

    other_events
  end

  @impl Caltar.Calendar.Provider
  def update(state, state, _options), do: :nothing

  def update(_old_state, new_state, _options) do
    {:update, new_state, new_state}
  end

  def request_events("thescore", sport, team_id) do
    TheScore.schedule(sport: sport, team_id: team_id)
  end

  def request_teams("thescore", sport) do
    TheScore.teams(sport: sport)
  end
end
