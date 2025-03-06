defmodule Caltar.Storage.Configuration.Sport do
  @behaviour Caltar.Storage.Configuration
  use Caltar, {:schema, persisted: false}

  alias Caltar.Storage.Configuration.Sport

  embedded_schema do
    field(:provider, :string)
    field(:sport, :string)
    field(:team_id, :string)
  end

  @provider_mapping %{
    "thescore" => ~w(nhl mlb nfl nba cfl pwhl),
    "hockey_tech" => ~w(ohl whl lhjmq)
  }

  @providers Map.keys(@provider_mapping)

  @required ~w(provider sport team_id)a
  def changeset(%Sport{} = sport \\ %Sport{}, params) do
    sport
    |> Ecto.Changeset.cast(params, @required)
    |> Ecto.Changeset.validate_required(@required)
    |> Ecto.Changeset.validate_inclusion(:provider, @providers)
    |> Box.Ecto.Changeset.update_valid(fn changeset ->
      Ecto.Changeset.validate_change(
        changeset,
        :sport,
        &validate_sport(&1, &2, Ecto.Changeset.get_field(changeset, :provider))
      )
    end)
  end

  defp validate_sport(:sport, sport, provider) do
    valid_sports = Map.fetch!(@provider_mapping, provider)

    if sport in valid_sports do
      []
    else
      [sport: "must be one of #{Enum.join(valid_sports, ", ")}"]
    end
  end

  @impl Caltar.Storage.Configuration
  def poller_spec(provider) do
    {Caltar.Calendar.Provider.Sport.Supervisor, provider: provider}
  end

  @hour div(:timer.hours(1), 1000)
  @impl Caltar.Storage.Configuration
  def poll_every_timer(_), do: @hour

  def providers, do: @provider_mapping
end
