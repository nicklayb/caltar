defmodule Caltar.Client.TheScore do
  use Caltar.Http, base_url: URI.parse("https://api.thescore.com")

  alias Caltar.Client.TheScore.Schema

  def schedule(options) do
    sport = Keyword.fetch!(options, :sport)
    team_id = Keyword.fetch!(options, :team_id)
    url = URI.parse("/#{sport}/teams/#{team_id}/events/full_schedule")

    with {:ok, %HttpResponse{status: 200, body: body}} <- request(url: url) do
      Starchoice.decode(body, Schema.Event)
    end
  end

  def event(options) do
    sport = Keyword.fetch!(options, :sport)
    team_id = Keyword.fetch!(options, :team_id)
    event_id = Keyword.fetch!(options, :event_id)
    url = URI.parse("/#{sport}/teams/#{team_id}/events/#{event_id}")

    with {:ok, %HttpResponse{status: 200, body: body}} <- request(url: url) do
      Starchoice.decode(body, Schema.Event)
    end
  end

  def teams(options) do
    sport = Keyword.fetch!(options, :sport)

    url = URI.parse("/#{sport}/teams")

    with {:ok, %HttpResponse{status: 200, body: body}} <- request(url: url) do
      Starchoice.decode(body, Schema.Team)
    end
  end
end
