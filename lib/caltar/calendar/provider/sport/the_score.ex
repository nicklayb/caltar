defmodule Caltar.Calendar.Provider.Sport.TheScore do
  use Caltar.Http, base_url: URI.parse("https://api.thescore.com")
  alias Caltar.Calendar.Provider.Sport.TeamParams
  alias Caltar.Calendar.Event
  alias Caltar.Calendar.Provider.Sport.EventParams

  def schedule(options) do
    sport = Keyword.fetch!(options, :sport)
    team_id = Keyword.fetch!(options, :team_id)
    url = URI.parse("/#{sport}/teams/#{team_id}/events/full_schedule")

    with {:ok, %HttpResponse{status: 200, body: body}} <- request(url: url) do
      {:ok, to_events(body, sport, team_id)}
    end
  end

  def event(options) do
    sport = Keyword.fetch!(options, :sport)
    team_id = Keyword.fetch!(options, :team_id)
    event_id = Keyword.fetch!(options, :event_id)
    url = URI.parse("/#{sport}/teams/#{team_id}/events/#{event_id}")

    with {:ok, %HttpResponse{status: 200, body: body}} <- request(url: url) do
      {:ok, to_event(body, sport, team_id)}
    end
  end

  def teams(options) do
    sport = Keyword.fetch!(options, :sport)
    url = URI.parse("/#{sport}/teams")

    with {:ok, %HttpResponse{status: 200, body: body}} <- request(url: url) do
      {:ok, to_teams(body)}
    end
  end

  defp to_teams(body) do
    Enum.map(body, &to_team/1)
  end

  defp to_team(params) do
    %TeamParams{
      id: Map.fetch!(params, "id"),
      full_name: Map.fetch!(params, "full_name")
    }
  end

  defp to_events(body, sport, team_id) do
    Enum.map(body, &to_event(&1, sport, team_id))
  end

  def to_event(params, sport, team_id) do
    box_score = Box.Map.get_with_default(params, "box_score", %{})

    away =
      params
      |> Map.fetch!("away_team")
      |> to_side(box_score, :away)

    home =
      params
      |> Map.fetch!("home_team")
      |> to_side(box_score, :home)

    starts_at = game_date(params)
    id = Map.fetch!(params, "id")
    progress = progress(box_score)

    summary = event_summary(progress.status, params, home, away)

    %Event{
      id: Enum.join(["thescore", sport, id], ":"),
      starts_at: starts_at,
      ends_at: starts_at,
      title: summary,
      params: %EventParams{
        id: id,
        sport: sport,
        game_date: Map.fetch!(params, "game_date"),
        team_id: team_id,
        home: home,
        away: away,
        progress: progress
      }
    }
  end

  defp event_summary(_, %{"summary" => summary}, _, _), do: summary

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

  defp to_side(team, box_score, side) do
    %EventParams.Side{
      avatar: avatar(team),
      name: Map.fetch!(team, "abbreviation"),
      score: score(box_score, side)
    }
  end

  defp score(nil, _), do: 0

  defp score(box_score, side) do
    box_score
    |> Box.Map.get_with_default("score", %{})
    |> Box.Map.get_with_default(to_string(side), %{})
    |> Box.Map.get_with_default("score", 0)
  end

  defp avatar(team) do
    team
    |> Map.fetch!("logos")
    |> Map.fetch!("small")
  end

  defp progress(%{
         "progress" => %{"status" => status, "clock" => clock, "segment_string" => clock_label}
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

  defp game_date(params) do
    params
    |> Map.fetch!("game_date")
    |> parse_date()
  end

  # "Sat, 26 Oct 2024 23:00:00 -0000"
  @date_format_regex ~r/^.*([0-9]{2}) (\w+) ([0-9]{4}) ([0-9]{2}:[0-9]{2}:[0-9]{2}).*$/
  defp parse_date(date) do
    case Regex.scan(@date_format_regex, date) do
      [[_, day, month_string, year, time]] ->
        day = String.to_integer(day)
        month = parse_month(month_string)
        year = String.to_integer(year)
        [hour, minute, second] = parse_time(time)

        year
        |> Date.new!(month, day)
        |> DateTime.new!(Time.new!(hour, minute, second))
        |> Caltar.Date.shift_timezone!()

      _ ->
        raise "Invalid date format #{date}"
    end
  end

  defp parse_month("Jan" <> _), do: 1
  defp parse_month("Feb" <> _), do: 2
  defp parse_month("Mar" <> _), do: 3
  defp parse_month("Apr" <> _), do: 4
  defp parse_month("May" <> _), do: 5
  defp parse_month("Jun" <> _), do: 6
  defp parse_month("Jul" <> _), do: 7
  defp parse_month("Aug" <> _), do: 8
  defp parse_month("Sep" <> _), do: 9
  defp parse_month("Oct" <> _), do: 10
  defp parse_month("Nov" <> _), do: 11
  defp parse_month("Dec" <> _), do: 12

  defp parse_time(time) do
    case String.split(time, ":") do
      [_, _, _] = parts ->
        Enum.map(parts, &String.to_integer/1)

      _ ->
        raise "Invalid time format #{time}"
    end
  end
end
