defmodule Caltar.Storage.Configuration.Birthdays do
  use Caltar, :schema

  alias Caltar.Storage.Provider
  alias Caltar.Calendar.Poller
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

  def child_spec(args) do
    %Provider{every: every, id: id, color: color, configuration: %Birthdays{birthdays: birthdays}} =
      Keyword.fetch!(args, :provider)

    supervisor_pid = Keyword.fetch!(args, :supervisor_pid)

    %{
      id: {__MODULE__, id},
      start:
        {Poller, :start_link,
         [
           [
             provider: {Caltar.Calendar.Provider.Birthdays, birthdays: birthdays} |> IO.inspect(),
             color: color,
             supervisor_pid: supervisor_pid,
             every: every || :never
           ]
         ]}
    }
  end
end
