defmodule Caltar.Calendar.Provider.Sport.HockeyTech do
  alias Caltar.Calendar.Event
  alias Caltar.Calendar.Provider.Sport.EventParams
  alias Caltar.Calendar.Provider.Sport.TeamParams
  alias Caltar.Client.HockeyTech, as: HockeyTechClient
  alias Caltar.Client.HockeyTech.Schema, as: HockeyTechSchema

  def schedule(options) do
    league = Keyword.fetch!(options, :sport)
    options = Keyword.put(options, :league, league)
    team_id = Keyword.fetch!(options, :team_id)

    with {:ok, {_league, season_id}} <- current_season_id(options),
         {:ok, events} <- HockeyTechClient.schedule([{:season_id, season_id} | options]) do
      {:ok, to_events(events, league, team_id)}
    end
  end

  def event(options) do
    with {:ok, events} <- schedule(options) do
      event_id = Keyword.fetch!(options, :event_id)
      sport = Keyword.fetch!(options, :sport)

      case Enum.find(events, &(&1.id == "hockey_tech:#{sport}:#{event_id}")) do
        nil -> {:error, :not_found}
        event -> {:ok, event}
      end
    end
  end

  def teams(options) do
    league = Keyword.fetch!(options, :sport)
    options = Keyword.put(options, :league, league)

    Box.Cache.memoize(Caltar.Cache, {:thescore, :teams, league}, fn ->
      with {:ok, {_league, season_id}} <- current_season_id(options),
           {:ok, teams} <- HockeyTechClient.teams([{:season_id, season_id} | options]) do
        {:ok, to_teams(teams)}
      end
    end)
  end

  defp current_season_id(options) do
    league = Keyword.fetch!(options, :sport)
    options = Keyword.put(options, :league, league)

    Box.Cache.memoize(Caltar.Cache, {:hockey_tech, :current_season, league}, fn ->
      HockeyTechClient.current_season(options)
    end)
  end

  defp to_teams(body) do
    Enum.map(body, &to_team/1)
  end

  defp to_team(%HockeyTechSchema.Team{id: id, name: name}) do
    %TeamParams{
      id: id,
      full_name: name
    }
  end

  defp to_events(events, sport, team_id) do
    Enum.map(events, &to_event(&1, sport, team_id))
  end

  def to_event(
        %HockeyTechSchema.Event{id: event_id, game_date: game_date} = event,
        sport,
        team_id
      ) do
    starts_at = Caltar.Date.shift_timezone!(game_date)

    summary = summary(event)

    home_side = to_side(event, sport, :home)
    away_side = to_side(event, sport, :away)

    progress = to_progress(event)

    %Event{
      id: Enum.join(["hockey_tech", sport, event_id], ":"),
      starts_at: starts_at,
      ends_at: starts_at,
      title: summary,
      params: %EventParams{
        id: event_id,
        sport: sport,
        team_id: team_id,
        home: home_side,
        away: away_side,
        progress: progress
      }
    }
  end

  defp to_progress(%HockeyTechSchema.Event{
         game_clock: clock,
         game_status: clock_label,
         status: status
       }) do
    [[clock]] = Regex.scan(~r/[0-9]{2}:[0-9]{2}$/, clock)

    clock_label =
      clock_label
      |> String.replace(clock, "")
      |> String.trim()

    %EventParams.Progress{
      status: status(status),
      clock: clock,
      clock_status: clock_label
    }
  end

  defp to_side(
         %HockeyTechSchema.Event{
           visiting_goal_count: score,
           visiting_team_nickname: name,
           visiting_team: id
         },
         sport,
         :away
       ) do
    %EventParams.Side{
      avatar: avatar(sport, id),
      name: name,
      score: score
    }
  end

  defp to_side(
         %HockeyTechSchema.Event{home_goal_count: score, home_team_nickname: name, home_team: id},
         sport,
         :home
       ) do
    %EventParams.Side{
      avatar: avatar(sport, id),
      name: name,
      score: score
    }
  end

  defp avatar(league, id) do
    "https://assets.leaguestat.com/#{league}/logos/#{id}.png"
  end

  defp summary(%HockeyTechSchema.Event{
         status: :upcoming,
         home_team_code: home,
         visiting_team_code: away
       }) do
    "#{away} @ #{home}"
  end

  defp summary(%HockeyTechSchema.Event{
         home_team_code: home,
         home_goal_count: home_score,
         visiting_team_code: away,
         visiting_goal_count: away_score
       }) do
    "#{away_score} #{away} @ #{home} #{home_score}"
  end

  defp status(:final), do: :finished
  defp status(:upcoming), do: :pending
  defp status(_), do: :in_progress
end
