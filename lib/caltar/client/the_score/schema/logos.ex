defmodule Caltar.Client.TheScore.Schema.Logos do
  use Starchoice.Decoder

  alias Caltar.Client.TheScore.Schema.Logos

  @local_fields ~w(large small w72xh72 tiny)a

  defstruct @local_fields

  defdecoder do
    Enum.map(@local_fields, &field/1)
  end

  def main(%Logos{small: small}), do: small
end
