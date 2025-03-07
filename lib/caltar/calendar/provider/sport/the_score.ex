defmodule Caltar.Calendar.Provider.Sport.TheScore do
  alias Caltar.Calendar.Event
  alias Caltar.Calendar.Provider.Sport.EventParams
  alias Caltar.Calendar.Provider.Sport.TeamParams
  alias Caltar.Client.TheScore, as: TheScoreClient
  alias Caltar.Client.TheScore.Schema, as: TheScoreSchema

  def schedule(options) do
    with {:ok, events} <- TheScoreClient.schedule(options) do
      sport = Keyword.fetch!(options, :sport)
      team_id = Keyword.fetch!(options, :team_id)
      {:ok, to_events(events, sport, team_id)}
    end
  end

  def event(options) do
    with {:ok, event} <- TheScoreClient.event(options) do
      sport = Keyword.fetch!(options, :sport)
      team_id = Keyword.fetch!(options, :team_id)
      {:ok, to_event(event, sport, team_id)}
    end
  end

  def teams(options) do
    sport = Keyword.fetch!(options, :sport)

    Box.Cache.memoize(
      Caltar.Cache,
      {:thescore, :teams, sport},
      [cache_match: &Box.Result.succeeded?/1],
      fn ->
        with {:ok, teams} <- TheScoreClient.teams(options) do
          {:ok, to_teams(teams)}
        end
      end
    )
  end

  defp to_teams(body) do
    Enum.map(body, &to_team/1)
  end

  defp to_team(%TheScoreSchema.Team{id: id, full_name: name}) do
    %TeamParams{
      id: id,
      full_name: name
    }
  end

  defp to_events(events, sport, team_id) do
    Enum.map(events, &to_event(&1, sport, team_id))
  end

  def to_event(
        %TheScoreSchema.Event{
          id: event_id,
          game_date: game_date,
          box_score: box_score,
          away_team: %TheScoreSchema.Team{} = away,
          home_team: %TheScoreSchema.Team{} = home
        } = event,
        sport,
        team_id
      ) do
    away_side = to_side(away, box_score, :away)

    home_side = to_side(home, box_score, :home)

    starts_at = Caltar.Date.shift_timezone!(game_date)
    progress = progress(box_score)

    summary = event_summary(progress.status, event.summary, home_side, away_side)

    %Event{
      id: Enum.join(["thescore", sport, event_id], ":"),
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

  defp event_summary(_, summary, _, _) when is_binary(summary), do: summary

  defp event_summary(:pending, _, %EventParams.Side{name: home_name}, %EventParams.Side{
         name: away_name
       }) do
    "#{away_name} @ #{home_name}"
  end

  defp event_summary(
         _,
         _params,
         %EventParams.Side{score: home_score, name: home_name},
         %EventParams.Side{
           score: away_score,
           name: away_name
         }
       ) do
    "#{away_score} #{away_name} @ #{home_name} #{home_score}"
  end

  defp to_side(
         %TheScoreSchema.Team{
           abbreviation: abbreviation,
           logos: %TheScoreSchema.Logos{small: small}
         },
         box_score,
         side
       ) do
    %EventParams.Side{
      avatar: small,
      name: abbreviation,
      score: score(box_score, side)
    }
  end

  defp score(nil, _), do: 0

  defp score(%TheScoreSchema.BoxScore{score: score}, side) do
    Map.fetch!(score, side)
  end

  defp progress(%TheScoreSchema.BoxScore{
         progress: %TheScoreSchema.Progress{
           clock: clock,
           clock_label: clock_label,
           status: status
         }
       }) do
    %EventParams.Progress{
      status: status(status),
      clock: clock,
      clock_status: clock_label
    }
  end

  defp progress(_) do
    %EventParams.Progress{
      status: :pending,
      clock: "0:00",
      clock_status: "-"
    }
  end

  defp status("final"), do: :finished
  defp status("in_progress"), do: :in_progress
  defp status(_), do: :pending
end
