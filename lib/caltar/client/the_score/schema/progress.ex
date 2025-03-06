defmodule Caltar.Client.TheScore.Schema.Progress do
  use Starchoice.Decoder

  @local_fields ~w(clock_label clock segment_description status)a

  defstruct @local_fields

  defdecoder do
    Enum.map(@local_fields, &field/1)
  end
end
