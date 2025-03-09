defmodule Caltar.Calendar.StorageSupervisor do
  use Supervisor

  alias Caltar.Calendar.Poller
  alias Caltar.Calendar.Server, as: CalendarServer
  alias Caltar.Storage

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: Keyword.get(args, :name, __MODULE__))
  end

  def init(_args) do
    children = load_children()
    Supervisor.init(children, strategy: :one_for_one)
  end

  defp load_children do
    Storage.Calendar
    |> Caltar.Repo.all()
    |> Enum.map(&build_child/1)
    |> then(
      &[
        {Registry, keys: :unique, name: registry_name()},
        Caltar.Storage.Controller
        | &1
      ]
    )
  end

  defp build_child(%Storage.Calendar{} = calendar) do
    {Caltar.Storage.Calendar.Supervisor, calendar: calendar}
  end

  def get_supervisor(slug) do
    Caltar.Calendar.StorageSupervisor
    |> Supervisor.which_children()
    |> Enum.find_value(fn
      {{Caltar.Storage.Calendar.Supervisor, ^slug}, pid, _, _} -> pid
      _ -> false
    end)
  end

  def get_calendar_provider_supervisor(slug_or_pid) do
    get_calendar_process(slug_or_pid, :provider_supervisor)
  end

  def get_calendar_controller(slug_or_pid) do
    get_calendar_process(slug_or_pid, :controller)
  end

  def get_calendar_server(slug_or_pid) do
    get_calendar_process(slug_or_pid, :server)
  end

  defp get_calendar_process(slug, process) when is_binary(slug) do
    slug
    |> get_supervisor()
    |> get_calendar_process(process)
  end

  defp get_calendar_process(supervisor_pid, process) when is_pid(supervisor_pid) do
    supervisor_pid
    |> Supervisor.which_children()
    |> Enum.find_value(&match_process(&1, process))
  end

  defp match_process({_, pid, _, [Caltar.Calendar.Server]}, :server), do: pid
  defp match_process({_, pid, _, [Caltar.Storage.Calendar.Controller]}, :controller), do: pid

  defp match_process(
         {_, pid, _, [DynamicSupervisor]},
         :provider_supervisor
       ),
       do: pid

  defp match_process(_, _), do: nil

  def refresh_poller(provider_id) do
    provider_id
    |> poller_name()
    |> GenServer.cast(:poll)
  end

  def register(key) do
    Registry.register(registry_name(), key, nil)
  end

  def poller_name(provider_id), do: registry_name({Poller, provider_id})

  def calendar_name(calendar_id), do: registry_name({CalendarServer, calendar_id})

  def registry_name({namespace, id}), do: {:via, Registry, {registry_name(), {namespace, id}}}

  def registry_name({namespace, id, value}),
    do: {:via, Registry, {registry_name(), {namespace, id}, value}}

  def registry_name, do: Caltar.Calendar.StorageSupervisor.Registry

  def registry_keys do
    Registry.select(registry_name(), [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
  end
end
