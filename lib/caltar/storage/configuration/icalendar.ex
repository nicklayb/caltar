defmodule Caltar.Storage.Configuration.Icalendar do
  @behaviour Caltar.Storage.Configuration
  use Caltar, {:schema, persisted: false}

  alias Caltar.Storage.Configuration.Icalendar

  embedded_schema do
    field(:url, :string)
    field(:icon, :string)
  end

  @required ~w(url)a
  @optional ~w(icon)a
  @castable @required ++ @optional
  def changeset(%Icalendar{} = icalendar \\ %Icalendar{}, params) do
    icalendar
    |> Ecto.Changeset.cast(params, @castable)
    |> Ecto.Changeset.validate_required(@required)
  end

  @impl Caltar.Storage.Configuration
  def poller_spec(_) do
    {:poller, Caltar.Calendar.Provider.Icalendar}
  end

  @quarter_hour div(:timer.minutes(15), 1000)
  @impl Caltar.Storage.Configuration
  def poll_every_timer(_), do: @quarter_hour
end
