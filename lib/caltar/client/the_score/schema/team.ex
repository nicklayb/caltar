defmodule Caltar.Client.TheScore.Schema.Team do
  use Starchoice.Decoder

  alias Caltar.Client.TheScore.Schema.Logos
  alias Caltar.Client.TheScore.Schema.Team

  @local_fields ~w(id abbreviation medium_name short_name colour_1 colour_2 name full_name location)a
  @other ~w(logos)a

  defstruct @local_fields ++ @other

  defdecoder do
    Enum.map(@local_fields, &field/1)
    field(:logos, with: Logos)
  end

  def main_logo(%Team{logos: logos}), do: Logos.main(logos)

  def same?(%{id: id}, %{id: id}), do: true
  def same?(_, _), do: false
end
