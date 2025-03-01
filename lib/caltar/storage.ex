defmodule Caltar.Storage do
  alias Caltar.Repo
  alias Caltar.Storage.Calendar
  alias Caltar.Storage.Provider

  def get_calendars do
    Repo.all(Calendar)
  end

  def provider_exists?(provider_id) do
    provider_id
    |> Provider.Query.by_id()
    |> Repo.exists?()
  end

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

  def get_provider(provider_id) do
    Provider.from()
    |> Provider.Query.by_id(provider_id)
    |> Repo.fetch()
  end
end
