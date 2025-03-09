defmodule Caltar.Storage.Configuration.Formula1 do
  @behaviour Caltar.Storage.Configuration
  use Caltar, {:schema, persisted: false}

  alias Caltar.Storage.Configuration.Formula1

  embedded_schema do
    field(:parts, {:array, :string}, default: [])
    field(:url, :string)
  end

  @parts [
    p1: "Practice 1",
    p2: "Practice 2",
    p3: "Practice 3",
    qualifying: "Qualifying",
    sprint: "Sprint",
    gp: "Grand Prix"
  ]
  @parts_string_keys @parts
                     |> Keyword.keys()
                     |> Enum.map(&to_string/1)

  def parts, do: @parts

  @required ~w(parts)a
  def changeset(%Formula1{} = formula_1 \\ %Formula1{}, params) do
    formula_1
    |> Ecto.Changeset.cast(params, @required)
    |> Ecto.Changeset.validate_required(@required)
    |> Ecto.Changeset.validate_length(:parts, min: 1)
    |> Box.Ecto.Changeset.update_valid(fn changeset ->
      Ecto.Changeset.validate_change(changeset, :parts, &validate_parts/2)
    end)
    |> Box.Ecto.Changeset.update_valid(&generate_url/1)
  end

  defp generate_url(%Ecto.Changeset{} = changeset) do
    parts = Ecto.Changeset.get_field(changeset, :parts)

    url =
      @parts_string_keys
      |> Enum.filter(&(&1 in parts))
      |> Enum.join("_")
      |> then(&"https://files-f1.motorsportcalendars.com/f1-calendar_#{&1}.ics")

    Ecto.Changeset.put_change(changeset, :url, url)
  end

  defp validate_parts(:parts, [_ | _] = parts) do
    {_, invalid_parts} = Enum.split_with(parts, &(&1 in @parts_string_keys))

    if Enum.any?(invalid_parts) do
      [parts: "#{inspect(invalid_parts)} are not valid"]
    else
      []
    end
  end

  @impl Caltar.Storage.Configuration
  def poller_spec(_) do
    {:poller, Caltar.Calendar.Provider.Icalendar}
  end

  @day div(:timer.hours(25), 1000)
  @impl Caltar.Storage.Configuration
  def poll_every_timer(_), do: @day
end
