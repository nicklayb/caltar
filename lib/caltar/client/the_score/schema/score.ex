defmodule Caltar.Client.TheScore.Schema.Score do
  use Starchoice.Decoder

  alias Caltar.Client.TheScore.Schema.Score

  @fields ~w(home away)a

  defstruct @fields

  defdecoder do
    field(:home, with: &Score.pull_score/1)
    field(:away, with: &Score.pull_score/1)
  end

  def pull_score(%{"score" => score}), do: score
end
