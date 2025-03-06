defmodule Caltar.Client.Geonames do
  use Caltar.Http,
    base_url: URI.parse("http://api.geonames.org")

  alias Caltar.Client.Geonames.Schema, as: GeonamesSchema

  # http://api.geonames.org/countryCodeJSON?lat=49.03&lng=10.2&username=nboisvert

  def country_code(options) do
    latitude = Keyword.fetch!(options, :latitude)
    longitude = Keyword.fetch!(options, :longitude)

    with {:ok, %HttpResponse{body: body}} <-
           request(url: URI.parse("/countryCodeJSON"), params: [lat: latitude, lng: longitude]) do
      Starchoice.decode(body, GeonamesSchema.CountryCode)
    end
  end
end
