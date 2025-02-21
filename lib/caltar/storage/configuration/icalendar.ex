defmodule Caltar.Storage.Configuration.Icalendar do
  use Caltar, {:schema, persisted: false}

  alias Caltar.Storage.Provider
  alias Caltar.Calendar.Poller
  alias Caltar.Storage.Configuration.Icalendar

  embedded_schema do
    field(:icalendar, {:map, :string})
  end

  @required ~w(icalendar)a
  def changeset(%Icalendar{} = icalendar \\ %Icalendar{}, params) do
    icalendar
    |> Ecto.Changeset.cast(params, @required)
    |> Ecto.Changeset.validate_required(@required)
    |> Box.Ecto.Changeset.update_valid(fn changeset ->
      Ecto.Changeset.validate_change(changeset, :icalendar, &validate_icalendar/2)
    end)
  end

  defp validate_icalendar(:icalendar, icalendar) do
    Enum.reduce_while(icalendar, [], fn {key, value}, acc ->
      cond do
        not is_binary(key) ->
          {:halt, [icalendar: "key must be strings, got: #{key}"]}

        key == "" ->
          {:halt, [icalendar: "key cannot be empty strings"]}

        not match?(%Date{}, value) ->
          {:halt, [icalendar: "value must be dates"]}

        true ->
          {:cont, acc}
      end
    end)
  end

  def child_spec(args) do
    %Provider{every: every, id: id, color: color, configuration: %Icalendar{icalendar: icalendar}} =
      Keyword.fetch!(args, :provider)

    supervisor_pid = Keyword.fetch!(args, :supervisor_pid)

    %{
      id: {__MODULE__, id},
      start:
        {Poller, :start_link,
         [
           [
             id: id,
             provider: {Caltar.Calendar.Provider.Icalendar, icalendar: icalendar},
             color: color,
             supervisor_pid: supervisor_pid,
             every: every || :never
           ]
         ]}
    }
  end
end
