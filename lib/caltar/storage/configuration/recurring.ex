defmodule Caltar.Storage.Configuration.Recurring do
  @behaviour Caltar.Storage.Configuration
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
  end

  @required ~w(name from_date every_count every_unit)a
  @optional ~w(to_date icon)a
  @castable @required ++ @optional
  def changeset(%Recurring{} = recurring \\ %Recurring{}, params) do
    recurring
    |> Ecto.Changeset.cast(params, @castable)
    |> Ecto.Changeset.validate_required(@required)
    |> Box.Ecto.Changeset.update_valid(fn changeset ->
      Ecto.Changeset.validate_change(changeset, :every_unit, &validate_unit/2)
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

  @impl Caltar.Storage.Configuration
  def poller_spec(_) do
    {:poller, Caltar.Calendar.Provider.Recurring}
  end

  @impl Caltar.Storage.Configuration
  @hour div(:timer.hours(1), 1000)
  def poll_every_timer(_), do: @hour

  def generate(%Recurring{icon: icon} = recurring, max_date) when is_binary(icon) do
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
