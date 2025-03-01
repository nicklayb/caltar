defmodule Caltar.Storage.UseCase.CreateProvider do
  use Box.UseCase

  alias Caltar.Storage.Calendar
  alias Caltar.Storage.Provider

  @impl Box.UseCase
  def validate(params, options) do
    case Box.Map.get_first(params, [:calendar_id, :calendar_slug]) do
      {:calendar_id, calendar_id} ->
        validate_calendar_exists(params, calendar_id)

      {:calendar_slug, calendar_slug} ->
        put_calendar_id(params, calendar_slug, options)

      nil ->
        {:error, :invalid}
    end
  end

  defp validate_calendar_exists(params, calendar_id) do
    if Caltar.Storage.calendar_exists?(calendar_id) do
      params = Box.Map.put_new(params, :color, Caltar.Color.random_pastel())
      {:ok, params}
    else
      {:error, :not_found}
    end
  end

  def put_calendar_id(params, slug, options) do
    with {:ok, %Calendar{id: calendar_id}} <- Caltar.Storage.get_calendar_by_slug(slug) do
      params
      |> Box.Map.put(:calendar_id, calendar_id)
      |> validate(options)
    end
  end

  @impl Box.UseCase
  def run(multi, params, _) do
    multi
    |> Ecto.Multi.insert(
      :provider,
      Caltar.Storage.Provider.changeset(params)
    )
    |> Ecto.Multi.run(:preloaded_provider, fn repo, %{provider: provider} ->
      {:ok, repo.preload(provider, [:calendar])}
    end)
  end

  @impl Box.UseCase
  def after_run(%{preloaded_provider: %Provider{calendar: %Calendar{slug: slug}} = provider}, _) do
    Caltar.PubSub.broadcast("calendar:#{slug}", {:provider_created, provider})
  end

  @impl Box.UseCase
  def return(%{provider: provider}, _) do
    provider
  end
end
