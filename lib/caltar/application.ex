defmodule Caltar.Application do
  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      Caltar.Repo,
      {Ecto.Migrator, repos: ecto_repos()},
      Caltar.PubSub,
      Caltar.Clock,
      Caltar.Calendar.StorageSupervisor,
      CaltarWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Caltar.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl Application
  def config_change(changed, _new, removed) do
    CaltarWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def ecto_repos, do: config(:ecto_repos)

  def release_name, do: config(:release_name)

  def locale, do: config(:locale)

  defp config(key) do
    Application.fetch_env!(:caltar, key)
  end
end
