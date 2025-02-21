defmodule Caltar.Storage.Calendar.Query do
  alias Caltar.Storage.Calendar
  require Ecto.Query

  def from(base_query \\ Calendar.from()) do
    base_query
  end

  def by_slug(query \\ from(), slug) do
    Ecto.Query.where(query, [calendar: calendar], calendar.slug == ^slug)
  end

  def by_main_slug(query \\ from()), do: by_slug(query, Calendar.main_slug())
end
