defmodule Caltar.Storage.UseCase.CreateProvider do
  alias Caltar.Storage.Calendar
  use Box.UseCase

  @impl Box.UseCase
  def validate(%{calendar_id: calendar_id} = params, _) do
    if Caltar.Storage.calendar_exists?(calendar_id) do
      {:ok, params}
    else
      {:error, :not_found}
    end
  end

  def validate(%{calendar_slug: calendar_slug} = params, options) do
    with {:ok, %Calendar{id: calendar_id}} <- Caltar.Storage.get_calendar_by_slug(calendar_slug) do
      params
      |> Map.put(:calendar_id, calendar_id)
      |> validate(options)
    end
  end

  @impl Box.UseCase
  def run(multi, params, _) do
    Ecto.Multi.insert(multi, :provider, Caltar.Storage.Provider.changeset(params))
  end

  @impl Box.UseCase
  def return(%{provider: provider}, _) do
    provider
  end
end
