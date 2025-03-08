defmodule Caltar.Calendar.Provider.Birthdays do
  use Caltar.Calendar.Provider
  use CaltarWeb.Gettext

  alias Caltar.Calendar.Provider.Birthdays.Params, as: BirthdaysParams
  alias Caltar.Calendar.Event
  alias Caltar.Storage.Configuration.Birthdays
  alias Caltar.Storage.Provider

  @impl Caltar.Calendar.Provider
  def poll(%DateTime{}, _previous_state, %Provider{
        configuration: %Birthdays{birthdays: birthdays}
      }) do
    now = Caltar.Date.now!()

    birthdays
    |> Enum.map(fn {name, date} ->
      age = now.year - date.year

      {name, age, Map.put(date, :year, now.year)}
    end)
    |> Box.Result.succeed()
  end

  @impl Caltar.Calendar.Provider
  def update(state, state, _), do: :nothing

  def update(_, new_state, _) do
    events =
      Enum.map(new_state, fn {name, age, date} ->
        full_date = Caltar.Date.date_time_from_date(date)

        %Event{
          id: "birthday|" <> name,
          title: name,
          starts_at: full_date,
          ends_at: full_date,
          params: %BirthdaysParams{age: age}
        }
      end)

    new_state
    |> update_state()
    |> with_events(events)
  end
end
