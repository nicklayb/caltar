defmodule Caltar.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Caltar.Clock,
      Caltar.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:caltar, :ecto_repos), skip: skip_migrations?()},
      Caltar.PubSub,
      CaltarWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Caltar.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    CaltarWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    System.get_env("RELEASE_NAME") != nil
  end
end
