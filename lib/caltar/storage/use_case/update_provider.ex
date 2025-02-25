defmodule Caltar.Storage.UseCase.UpdateProvider do
  alias Caltar.Storage.Provider
  alias Caltar.Storage.Calendar
  use Box.UseCase

  @impl Box.UseCase
  def validate(params, _) do
    with {:provider_id, provider_id} <- Box.Map.get_first(params, [:provider_id]),
         true <- Caltar.Storage.provider_exists?(provider_id) do
      {:ok, {provider_id, params}}
    else
      _ -> {:error, :not_found}
    end
  end

  @impl Box.UseCase
  def run(multi, {provider_id, params}, _) do
    multi
    |> Ecto.Multi.one(:get_provider, Provider.Query.by_id(provider_id))
    |> Ecto.Multi.update(
      :provider,
      fn %{get_provider: %Provider{} = provider} ->
        Caltar.Storage.Provider.changeset(provider, params)
      end
    )
    |> Ecto.Multi.run(:preloaded_provider, fn repo, %{provider: provider} ->
      {:ok, repo.preload(provider, [:calendar])}
    end)
  end

  @impl Box.UseCase
  def after_run(%{preloaded_provider: %Provider{calendar: %Calendar{slug: slug}}}, _) do
    Caltar.PubSub.broadcast("calendar:#{slug}", :calendar_updated)
  end

  @impl Box.UseCase
  def return(%{provider: provider}, _) do
    provider
  end
end
