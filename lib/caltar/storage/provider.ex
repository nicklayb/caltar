defmodule Caltar.Storage.Provider do
  use Caltar, :schema

  import PolymorphicEmbed, only: [polymorphic_embeds_one: 2]
  require Ecto.Query

  alias Caltar.Storage.Calendar
  alias Caltar.Storage.Provider

  schema("providers") do
    field(:color, :string)
    field(:every, :integer)

    belongs_to(:calendar, Calendar)

    polymorphic_embeds_one(:configuration,
      types: [
        birthdays: Caltar.Storage.Configuration.Birthdays
      ],
      on_type_not_found: :raise,
      on_replace: :update
    )

    timestamps()
  end

  @required ~w(calendar_id color)a
  @optional ~w(every)a
  @castable @required ++ @optional
  def changeset(%Provider{} = provider \\ %Provider{}, params) do
    provider
    |> Ecto.Changeset.cast(params, @castable)
    |> PolymorphicEmbed.cast_polymorphic_embed(:configuration, required: true)
    |> Ecto.Changeset.validate_required(@required)
  end
end
