defmodule Caltar.Storage.Configuration.Birthdays do
  use Caltar, {:schema, persisted: false}

  alias Caltar.Storage.Configuration.Birthdays

  embedded_schema do
    field(:birthdays, {:map, :date})
    field(:birthdays_input, :string)
  end

  @optional ~w(birthdays)a
  @required ~w(birthdays_input)a
  @castable @optional ++ @required

  def changeset(%Birthdays{} = birthdays \\ %Birthdays{}, params) do
    birthdays
    |> Ecto.Changeset.cast(params, @castable)
    |> Box.Ecto.Changeset.update_valid(&cast_birthdays_input/1)
    |> Box.Ecto.Changeset.update_valid(fn changeset ->
      Ecto.Changeset.validate_change(changeset, :birthdays, &validate_birthdays/2)
    end)
    |> Ecto.Changeset.validate_required(@required)
  end

  defp validate_birthdays(:birthdays, birthdays) do
    Enum.reduce_while(birthdays, [], fn {key, value}, acc ->
      cond do
        not is_binary(key) ->
          {:halt, [birthdays: "key must be strings, got: #{key}"]}

        key == "" ->
          {:halt, [birthdays: "key cannot be empty strings"]}

        not match?(%Date{}, value) ->
          {:halt, [birthdays: "value must be dates"]}

        true ->
          {:cont, acc}
      end
    end)
  end

  defp cast_birthdays_input(%Ecto.Changeset{} = changeset) do
    case Ecto.Changeset.get_change(changeset, :birthdays_input) do
      nil ->
        changeset

      string ->
        case parse_input(string) do
          {:ok, map} ->
            Ecto.Changeset.put_change(changeset, :birthdays, map)

          _ ->
            Ecto.Changeset.add_error(changeset, :birthdays_input, "is invalid")
        end
    end
  end

  defp parse_input(string) do
    string
    |> String.trim()
    |> String.split("\n")
    |> Enum.reduce_while({:ok, %{}}, fn line, {:ok, acc} ->
      trimmed_line = String.trim(line)

      case parse_line(trimmed_line) do
        {:ok, {name, date}} ->
          {:cont, {:ok, Map.put(acc, name, date)}}

        :ignore ->
          {:cont, {:ok, acc}}

        error ->
          {:halt, error}
      end
    end)
  end

  defp parse_line(""), do: :ignore

  defp parse_line(line) do
    with [key, value] when key != "" <- String.split(line, ":", parts: 2),
         {:ok, date} <- Date.from_iso8601(value) do
      {:ok, {key, date}}
    else
      _ ->
        {:error, :invalid_input}
    end
  end

  def poller_spec(_provider) do
    {:poller, Caltar.Calendar.Provider.Birthdays}
  end
end
