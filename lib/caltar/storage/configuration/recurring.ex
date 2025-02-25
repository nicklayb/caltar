defmodule Caltar.Storage.Configuration.Recurring do
  use Caltar, {:schema, persisted: false}

  alias Caltar.Calendar.Event
  alias Caltar.Calendar.Marker
  alias Caltar.Storage.Configuration.Recurring

  embedded_schema do
    field(:name, :string)
    field(:icon, :string)
    field(:every_count, :integer)
    field(:every_unit, :string)
    field(:from_date, :date)
    field(:to_date, :date)
    field(:is_marker, :boolean, default: false)
  end

  @required ~w(name from_date every_count every_unit)a
  @optional ~w(to_date icon is_marker)a
  @castable @required ++ @optional
  def changeset(%Recurring{} = recurring \\ %Recurring{}, params) do
    recurring
    |> Ecto.Changeset.cast(params, @castable)
    |> Ecto.Changeset.validate_required(@required)
    |> Box.Ecto.Changeset.update_valid(fn changeset ->
      changeset
      |> validate_marker_has_icon()
      |> Ecto.Changeset.validate_change(:every_unit, &validate_unit/2)
    end)
  end

  @units ~w(day week month year)a
  @string_units Enum.map(@units, &to_string/1)

  def units, do: @units

  defp validate_unit(:every_unit, unit) when unit in @string_units do
    []
  end

  defp validate_unit(:every_unit, _) do
    [every_unit: "is invalid"]
  end

  defp validate_marker_has_icon(%Ecto.Changeset{} = changeset) do
    is_marker? = Ecto.Changeset.get_field(changeset, :is_marker)
    icon = Ecto.Changeset.get_field(changeset, :icon)

    cond do
      is_marker? and is_nil(icon) ->
        Ecto.Changeset.add_error(changeset, :icon, "must be present when marker")

      not is_marker? and not is_nil(icon) ->
        Ecto.Changeset.add_error(changeset, :icon, "must be empty for non-marker")

      true ->
        changeset
    end
  end

  def poller_spec(%Recurring{} = recurring) do
    {Caltar.Calendar.Provider.Recurring, recurring}
  end

  def generate(%Recurring{is_marker: true} = recurring, max_date) do
    generate_occurences(recurring, max_date, fn current_date ->
      %Marker{
        id: recurring.id <> "|" <> Date.to_string(current_date),
        icon: recurring.icon,
        date: current_date
      }
    end)
  end

  def generate(%Recurring{} = recurring, max_date) do
    generate_occurences(recurring, max_date, fn current_date ->
      date_time = Caltar.Date.date_time_from_date(current_date, ~T[00:00:00])

      %Event{
        id: recurring.id <> "|" <> Date.to_string(current_date),
        starts_at: date_time,
        ends_at: date_time,
        title: recurring.name
      }
    end)
  end

  defp generate_occurences(%Recurring{from_date: from_date} = recurring, max_date, function) do
    generate_occurences(recurring, [], from_date, max_date, function)
  end

  defp generate_occurences(
         %Recurring{
           every_unit: unit,
           every_count: count
         } = recurring,
         acc,
         current_date,
         max_date,
         function
       ) do
    if before_to_date?(recurring, current_date) and Date.before?(current_date, max_date) do
      new_acc = [function.(current_date) | acc]
      shifted_date = Date.shift(current_date, [{String.to_existing_atom(unit), count}])
      generate_occurences(recurring, new_acc, shifted_date, max_date, function)
    else
      acc
    end
  end

  defp before_to_date?(%Recurring{to_date: nil}, _date), do: true

  defp before_to_date?(%Recurring{to_date: to_date}, date) do
    Date.before?(date, to_date)
  end
end
