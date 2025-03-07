defmodule Caltar.Calendar.Provider.Icalendar.Formula1Params do
  defstruct [:country_code, :short_name]

  alias Caltar.Client.Geonames.Schema.CountryCode
  alias Caltar.Client.Geonames
  alias Caltar.Calendar.Provider.Icalendar.Formula1Params

  def build(%ICalendar.Event{summary: summary, geo: geo}) do
    short_name = extract_short_name(summary)

    country_code =
      case get_country_code(geo) do
        {:ok, code} ->
          code

        _ ->
          nil
      end

    %Formula1Params{
      short_name: short_name,
      country_code: country_code
    }
  end

  defp extract_short_name(summary) do
    cond do
      summary =~ "Sprint Qualifying" -> "Sprint Q"
      summary =~ "Sprint" -> "Sprint"
      summary =~ "FP1" -> "FP1"
      summary =~ "FP2" -> "FP2"
      summary =~ "FP3" -> "FP3"
      summary =~ "Qualifying" -> "Qualifying"
      true -> "Grand Prix"
    end
  end

  defp get_country_code({latitude, longitude}) do
    Box.Cache.memoize(
      Caltar.Cache,
      {:country_code, latitude, longitude},
      [cache_match: &Box.Result.succeeded?/1],
      fn ->
        with {:ok, %CountryCode{country_code: country_code}} <-
               Geonames.country_code(latitude: latitude, longitude: longitude) do
          {:ok, country_code}
        end
      end
    )
  end
end
