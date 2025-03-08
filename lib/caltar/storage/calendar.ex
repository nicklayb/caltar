defmodule Caltar.Storage.Calendar do
  use Caltar, {:schema, name: :calendar}

  alias Caltar.Storage.Calendar
  alias Caltar.Storage.Provider

  @main_slug "main"

  schema("calendars") do
    field(:name, :string)
    field(:slug, :string)

    field(:display_mode, Box.Ecto.DynamicType, decoder: Caltar.Storage.Calendar.DisplayMode)

    has_many(:providers, Provider)

    timestamps()
  end

  @required ~w(name display_mode)a
  def changeset(%Calendar{} = calendar \\ %Calendar{}, params) do
    calendar
    |> Ecto.Changeset.cast(params, @required)
    |> Ecto.Changeset.validate_required(@required)
    |> Box.Ecto.Changeset.update_valid(fn changeset ->
      Box.Ecto.Changeset.generate_slug(changeset, source: :name, exists?: &slug_exists?/1)
    end)
  end

  def main_slug, do: @main_slug

  defp slug_exists?(test_slug) do
    Calendar
    |> Ecto.Query.where([q], q.slug == ^test_slug)
    |> Caltar.Repo.exists?()
  end
end
