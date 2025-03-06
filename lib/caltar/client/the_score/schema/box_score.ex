defmodule Caltar.Client.TheScore.Schema.BoxScore do
  use Starchoice.Decoder

  alias Caltar.Client.TheScore.Schema.Progress
  alias Caltar.Client.TheScore.Schema.Score

  @fields ~w(progress score)a

  defstruct @fields

  defdecoder do
    field(:progress, with: Progress)
    field(:score, with: Score)
  end
end
