defmodule Caltar.Client.HockeyTech do
  use Caltar.Http,
    base_url: "https://lscluster.hockeytech.com/",
    params: [
      key: "f1aa699db3d81487",
      fmt: "json"
    ]

  alias Caltar.Client.HockeyTech.Schema

  @known_leagues ~w(whl ohl lhjmq)

  def schedule(options) do
    with {:ok, league} <- fetch_league(options),
         {:ok, season_id} <- fetch_season_id(options),
         params <-
           merge_with([client_code: league, view: "schedule", season_id: season_id], options, [
             :team_id
           ]),
         {:ok, %HttpResponse{status: 200, body: %{"SiteKit" => site_kit}}} <-
           feed_module_kit(params: params),
         {:ok, %Schema.SiteKit{body: body}} <-
           Starchoice.decode(
             site_kit,
             Schema.SiteKit.decoder("Schedule", Schema.Event)
           ) do
      {:ok, body}
    end
  end

  def teams(options) do
    with {:ok, league} <- fetch_league(options),
         {:ok, season_id} <- fetch_season_id(options),
         {:ok, %HttpResponse{status: 200, body: %{"SiteKit" => site_kit}}} <-
           feed_module_kit(
             params: [client_code: league, view: "teamsbyseason", season_id: season_id]
           ),
         {:ok, %Schema.SiteKit{body: body}} <-
           Starchoice.decode(
             site_kit,
             Schema.SiteKit.decoder("Teamsbyseason", Schema.Team)
           ) do
      {:ok, body}
    end
  end

  def current_season(options) do
    with {:ok, league} <- fetch_league(options),
         {:ok, %HttpResponse{status: 200, body: %{"SiteKit" => site_kit}}} <-
           feed_module_kit(params: [client_code: league]),
         {:ok, %Schema.SiteKit{parameters: %{"season_id" => season_id}}} <-
           Starchoice.decode(site_kit, Schema.SiteKit.decoder()) do
      {:ok, {league, season_id}}
    end
  end

  defp fetch_season_id(options) do
    require_option(options, :season_id)
  end

  defp fetch_league(options) do
    require_option(options, :league, &(&1 in @known_leagues))
  end

  defp require_option(options, key, validate_value \\ fn _ -> true end) do
    case Keyword.fetch(options, key) do
      {:ok, value} ->
        if validate_value.(value) do
          {:ok, value}
        else
          {:error, {:invalid_option, key}}
        end

      :error ->
        {:error, {:missing_option, key}}
    end
  end

  defp feed_module_kit(options) do
    client_code =
      options
      |> Keyword.fetch!(:params)
      |> Keyword.fetch!(:client_code)

    request(
      [
        url: URI.parse("/feed"),
        params: [
          feed: "modulekit",
          lang: current_language(client_code)
        ]
      ],
      options
    )
  end

  defp current_language("lhjmq") do
    case Caltar.Application.locale() do
      "fr" -> "fr"
      _ -> "en"
    end
  end

  defp current_language(_) do
    "en"
  end

  defp merge_with(params, options, keys) do
    Enum.reduce(keys, params, fn key, acc ->
      case Keyword.get(options, key) do
        nil ->
          acc

        value ->
          Keyword.put(acc, key, value)
      end
    end)
  end
end
