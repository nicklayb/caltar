defmodule Caltar.Client.TheScore.Schema.Standing do
  use Starchoice.Decoder

  alias Caltar.Client.TheScore.Schema.Standing
  alias Caltar.Client.TheScore.Schema.Team

  @fields ~w(id place short_record points wins losses ties)a
  @other ~w(team)a

  defstruct @fields ++ @other

  defdecoder do
    Enum.map(@fields, &field(&1))
    field(:team, with: Team)
  end

  def team_id(%Standing{team: %{id: id}}), do: id

  def team_id(_), do: nil
end
