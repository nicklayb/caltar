defmodule Caltar.Storage.Configuration.Icalendar do
  use Caltar, {:schema, persisted: false}
  @behaviour Caltar.Storage.Configuration

  alias Caltar.Storage.Configuration.Icalendar

  embedded_schema do
    field(:url, :string)
  end

  @required ~w(url)a
  def changeset(%Icalendar{} = icalendar \\ %Icalendar{}, params) do
    icalendar
    |> Ecto.Changeset.cast(params, @required)
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
