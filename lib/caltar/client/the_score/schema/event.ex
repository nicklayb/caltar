defmodule Caltar.Client.TheScore.Schema.Event do
  use Starchoice.Decoder

  alias Caltar.Client.TheScore.Schema.BoxScore
  alias Caltar.Client.TheScore.Schema.Event
  alias Caltar.Client.TheScore.Schema.Team

  @local_fields ~w(status summary api_uri id)a
  @other ~w(game_date away_team home_team box_score)a

  defstruct @local_fields ++ @other

  defdecoder do
    Enum.map(@local_fields, &field/1)
    field(:box_score, with: BoxScore)
    field(:away_team, with: Team)
    field(:home_team, with: Team)
    field(:game_date, with: &Event.parse_date/1)
  end

  def sport(%Event{api_uri: api_uri}), do: sport(api_uri)

  def sport(api_uri) do
    [_, sport | _] = String.split(api_uri, "/")
    sport
  end

  # "Sat, 26 Oct 2024 23:00:00 -0000"
  @date_format_regex ~r/^.*([0-9]{2}) (\w+) ([0-9]{4}) ([0-9]{2}:[0-9]{2}:[0-9]{2}).*$/
  def parse_date(date) do
    case Regex.scan(@date_format_regex, date) do
      [[_, day, month_string, year, time]] ->
        day = String.to_integer(day)
        month = parse_month(month_string)
        year = String.to_integer(year)
        [hour, minute, second] = parse_time(time)

        year
        |> Date.new!(month, day)
        |> DateTime.new!(Time.new!(hour, minute, second))

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
