defmodule Caltar.Storage do
  alias Caltar.Storage.Calendar
  alias Caltar.Repo

  def main_calendar do
    Calendar.from()
    |> Calendar.Query.by_main_slug()
    |> Repo.fetch()
  end
end
