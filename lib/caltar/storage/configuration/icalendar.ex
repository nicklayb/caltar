defmodule Caltar.Storage.Configuration.Icalendar do
  use Caltar, {:schema, persisted: false}

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

  def poller_spec(_) do
    {:poller, Caltar.Calendar.Provider.Icalendar}
  end
end
