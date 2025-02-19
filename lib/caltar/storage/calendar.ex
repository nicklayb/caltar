defmodule Caltar.Storage.Calendar do
  use Caltar, :schema

  require Ecto.Query

  alias Caltar.Storage.Calendar
  alias Caltar.Storage.Provider

  schema("calendars") do
    field(:name, :string)
    field(:slug, :string)

    has_many(:providers, Provider)

    timestamps()
  end

  @required ~w(name)a
  def changeset(%Calendar{} = calendar \\ %Calendar{}, params) do
    calendar
    |> Ecto.Changeset.cast(params, @required)
    |> Ecto.Changeset.validate_required(@required)
    |> Box.Ecto.Changeset.update_valid(fn changeset ->
      Box.Ecto.Changeset.generate_slug(changeset, source: :name, exists?: &slug_exists?/1)
    end)
  end

  defp slug_exists?(test_slug) do
    Calendar
    |> Ecto.Query.where([q], q.slug == ^test_slug)
    |> Caltar.Repo.exists?()
  end
end
