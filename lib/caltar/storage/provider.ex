defmodule Caltar.Storage.Provider do
  use Caltar, {:schema, name: :provider}

  import PolymorphicEmbed, only: [polymorphic_embeds_one: 2]

  alias Caltar.Storage.Calendar
  alias Caltar.Storage.Provider

  schema("providers") do
    field(:name, :string)
    field(:color, Caltar.Ecto.Types.Color)
    field(:every, :integer)

    field(:coniguration_type, :string, virtual: true)

    belongs_to(:calendar, Calendar)

    polymorphic_embeds_one(:configuration,
      types: [
        birthdays: Caltar.Storage.Configuration.Birthdays,
        icalendar: Caltar.Storage.Configuration.Icalendar,
        formula_1: Caltar.Storage.Configuration.Formula1,
        recurring: Caltar.Storage.Configuration.Recurring,
        sport: Caltar.Storage.Configuration.Sport
      ],
      on_type_not_found: :raise,
      on_replace: :update
    )

    timestamps()
  end

  @minimum_every_seconds 15
  @required ~w(calendar_id name color)a
  @optional ~w(every)a
  @castable @required ++ @optional
  def changeset(%Provider{} = provider \\ %Provider{}, params) do
    provider
    |> Ecto.Changeset.cast(params, @castable)
    |> PolymorphicEmbed.cast_polymorphic_embed(:configuration, required: true)
    |> Ecto.Changeset.validate_required(@required)
    |> Ecto.Changeset.validate_number(:every, greater_than_or_equal_to: @minimum_every_seconds)
    |> Box.Ecto.Changeset.update_valid(&set_every_from_configuration/1)
  end

  defp set_every_from_configuration(%Ecto.Changeset{} = changeset) do
    case Ecto.Changeset.get_field(changeset, :configuration) do
      %struct{} = configuration ->
        every =
          case struct.poll_every_timer(configuration) do
            :never -> nil
            integer -> integer
          end

        Ecto.Changeset.put_change(changeset, :every, every)
    end
  end

  def configuration_type(%Provider{configuration: nil}), do: nil

  def configuration_type(%Provider{configuration: %struct{}}) do
    PolymorphicEmbed.get_polymorphic_type(Provider, :configuration, struct)
  end
end
