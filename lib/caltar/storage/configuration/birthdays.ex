defmodule Caltar.Storage.Configuration.Birthdays do
  use Caltar, {:schema, persisted: false}

  alias Caltar.Storage.Configuration.Birthdays

  embedded_schema do
    field(:birthdays, {:map, :date})
  end

  @required ~w(birthdays)a
  def changeset(%Birthdays{} = birthdays \\ %Birthdays{}, params) do
    birthdays
    |> Ecto.Changeset.cast(params, @required)
    |> Ecto.Changeset.validate_required(@required)
    |> Box.Ecto.Changeset.update_valid(fn changeset ->
      Ecto.Changeset.validate_change(changeset, :birthdays, &validate_birthdays/2)
    end)
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

  def poller_spec(%Birthdays{} = birthdays) do
    {Caltar.Calendar.Provider.Birthdays, birthdays}
  end
end
