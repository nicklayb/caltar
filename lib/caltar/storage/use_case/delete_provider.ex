defmodule Caltar.Storage.UseCase.DeleteProvider do
  use Box.UseCase

  alias Caltar.Storage.Calendar
  alias Caltar.Storage.Provider

  @impl Box.UseCase
  def validate(params, _) do
    with {:provider_id, provider_id} <- Box.Map.get_first(params, [:provider_id]),
         true <- Caltar.Storage.provider_exists?(provider_id) do
      {:ok, %{provider_id: provider_id}}
    else
      _ -> {:error, :not_found}
    end
  end

  @impl Box.UseCase
  def run(multi, params, _) do
    multi
    |> Ecto.Multi.one(:provider, query(params))
    |> Ecto.Multi.run(:preloaded_provider, fn repo, %{provider: provider} ->
      {:ok, repo.preload(provider, [:calendar])}
    end)
    |> Ecto.Multi.delete_all(
      :delete_provider,
      query(params)
    )
  end

  defp query(%{provider_id: provider_id}) do
    Provider.Query.by_id(provider_id)
  end

  @impl Box.UseCase
  def after_run(%{preloaded_provider: %Provider{calendar: %Calendar{slug: slug}} = provider}, _) do
    Caltar.PubSub.broadcast("calendar:#{slug}", {:provider_deleted, provider})
  end

  @impl Box.UseCase
  def return(%{provider: provider}, _) do
    provider
  end
end
