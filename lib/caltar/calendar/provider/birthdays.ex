defmodule Caltar.Calendar.Provider.Birthdays do
  alias Caltar.Storage.Configuration.Birthdays
  alias Caltar.Calendar.Event
  @behaviour Caltar.Calendar.Provider

  @impl Caltar.Calendar.Provider
  def poll(%DateTime{}, _previous_state, %Birthdays{birthdays: birthdays}) do
    now = Caltar.Date.now!()

    birthdays
    |> Enum.map(fn {name, date} ->
      {name, Map.put(date, :year, now.year)}
    end)
    |> Box.Result.succeed()
  end

  @impl Caltar.Calendar.Provider
  def update(state, state, _), do: :nothing

  def update(_, new_state, _) do
    events =
      Enum.map(new_state, fn {name, date} ->
        full_date = Caltar.Date.date_time_from_date(date)

        %Event{
          id: "birthday|" <> name,
          title: "🎂 #{name}",
          starts_at: full_date,
          ends_at: full_date
        }
      end)

    {:update, new_state, events}
  end
end
