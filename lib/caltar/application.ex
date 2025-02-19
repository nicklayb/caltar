defmodule Caltar.Application do
  use Application

  alias Caltar.Calendar.Poller

  @impl true
  def start(_type, _args) do
    children = [
      Caltar.Repo,
      {Ecto.Migrator, repos: ecto_repos()},
      Caltar.PubSub,
      Caltar.Clock,
      {Caltar.Calendar.StaticSupervisor,
       name: Caltar.Calendar.Main,
       providers: [
         {Poller,
          provider:
            {Caltar.Calendar.Provider.Birthdays,
             birthdays: [
               {"Adrien", ~D[2024-06-08]},
               {"Nicolas", ~D[1993-03-20]},
               {"Eve-Lynn", ~D[1996-07-03]},
               {"Alexis", ~D[2013-02-22]}
             ]},
          every: :never}
       ]},
      Caltar.Calendar.StorageSupervisor,
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

  def ecto_repos, do: config(:ecto_repos)

  def release_name, do: config(:release_name)

  def locale, do: config(:locale)

  defp config(key) do
    Application.fetch_env!(:caltar, key)
  end
end
