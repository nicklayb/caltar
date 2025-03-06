defmodule Caltar.Calendar.Provider.Sport.Supervisor do
  use Supervisor

  alias Caltar.Calendar.Poller
  alias Caltar.Calendar.StorageSupervisor

  @registry_namespace Caltar.Calendar.Provider.Sport.Supervisor
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  def init(args) do
    provider = Keyword.fetch!(args, :provider)

    children = [
      {Poller,
       id: provider.id,
       color: provider.color,
       every: provider.every,
       calendar_id: provider.calendar_id,
       module: Caltar.Calendar.Provider.SportSchedule,
       options: provider},
      {DynamicSupervisor,
       strategy: :one_for_one,
       name:
         StorageSupervisor.registry_name(
           {@registry_namespace, provider.id, provider.configuration.__struct__}
         )}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  def start_child(provider_id, child_spec) do
    {@registry_namespace, provider_id}
    |> StorageSupervisor.registry_name()
    |> DynamicSupervisor.start_child(child_spec)
  end
end
