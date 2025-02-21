defmodule Caltar.Storage do
  alias Caltar.Storage.Calendar
  alias Caltar.Repo

  def calendar_exists?(calendar_id) do
    calendar_id
    |> Calendar.Query.by_id()
    |> Repo.exists?()
  end

  def main_calendar do
    get_calendar_by_slug(Calendar.main_slug())
  end

  def get_calendar_by_slug(slug) do
    Calendar.from()
    |> Calendar.Query.by_slug(slug)
    |> Repo.fetch()
  end
end
