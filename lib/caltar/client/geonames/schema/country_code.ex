defmodule Caltar.Client.Geonames.Schema.CountryCode do
  use Starchoice.Decoder

  @local_fields_snake_case ~w(country_code country_name)a
  @local_fields ~w(distance languages)a

  defstruct @local_fields ++ @local_fields_snake_case

  defdecoder do
    Enum.map(@local_fields, &field/1)
    field(:country_code, source: "countryCode")
    field(:country_name, source: "countryName")
  end
end
