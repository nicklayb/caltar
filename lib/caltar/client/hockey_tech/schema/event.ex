defmodule Caltar.Client.HockeyTech.Schema.Event do
  use Starchoice.Decoder

  alias Caltar.Client.HockeyTech.Schema.Event

  require Logger

  @local_fields ~w(
    id
    league_code
    home_team
    home_team_code
    home_team_city
    home_team_nickname
    home_goal_count
    visiting_team
    visiting_team_code
    visiting_team_city
    visiting_team_nickname
    visiting_goal_count
    game_clock
    game_status
  )a
  @casting_fields ~w(game_date status)a

  defstruct @local_fields ++ @casting_fields

  defdecoder do
    Enum.map(@local_fields, &field/1)
    field(:game_date, source: "GameDateISO8601", with: &Event.cast_date/1)
    field(:status, with: &Event.cast_status/1)
  end

  def cast_date(date) do
    case DateTime.from_iso8601(date) do
      {:ok, date, _} ->
        date

      _ ->
        {:invalid, date}
    end
  end

  def cast_status("4"), do: :final
  def cast_status("3"), do: :ot
  def cast_status("2"), do: :live
  def cast_status("1"), do: :upcoming

  def cast_status(other) do
    Logger.warning("[#{inspect(__MODULE__)}] Unknown game_status #{other}")
    :live
  end
end
