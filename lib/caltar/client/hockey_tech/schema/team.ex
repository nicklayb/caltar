defmodule Caltar.Client.HockeyTech.Schema.Team do
  use Starchoice.Decoder

  @local_fields ~w(city code division_id division_long_name division_short_name id name nickname team_caption team_logo_url)a

  defstruct @local_fields

  defdecoder do
    Enum.map(@local_fields, &field/1)
  end
end
