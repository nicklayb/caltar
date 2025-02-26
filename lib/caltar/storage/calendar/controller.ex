defmodule Caltar.Calendar.Controller do
  use GenServer

  require Logger

  alias Caltar.Calendar.Poller
  alias Caltar.Repo
  alias Caltar.Storage.Provider
  alias Caltar.Calendar.Controller

  defstruct [:slug, :supervisor_pid, provider_pids: %{}]

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    state =
      args
      |> init_state()
      |> subscribe()

    log(:info, state, "started")

    send(self(), :init)

    {:ok, state}
  end

  def handle_info(
        %Box.PubSub.Message{
          message: :provider_updated,
          params: %Provider{id: provider_id} = provider
        },
        state
      ) do
    log(:info, state, "[#{provider_id}] provider updated")
    state = restart_provider(state, provider)
    {:noreply, state}
  end

  def handle_info(
        %Box.PubSub.Message{message: :provider_deleted, params: %Provider{id: provider_id}},
        state
      ) do
    log(:info, state, "[#{provider_id}] provider deleted")
    state = shutdown_provider(state, provider_id)
    {:noreply, state}
  end

  def handle_info(
        %Box.PubSub.Message{
          message: :provider_created,
          params: %Provider{id: provider_id} = provider
        },
        state
      ) do
    log(:info, state, "[#{provider_id}] created")
    state = start_provider(state, provider)
    {:noreply, state}
  end

  def handle_info(%Box.PubSub.Message{}, state) do
    {:noreply, state}
  end

  def handle_info(:init, %Controller{} = state) do
    state = start_providers(state)
    {:noreply, state}
  end

  defp poller_child_spec(
         %Provider{
           id: id,
           configuration: %configuration_struct{} = configuration,
           every: every,
           color: color
         },
         %Controller{supervisor_pid: supervisor_pid}
       ) do
    %{
      id: {__MODULE__, id},
      start:
        {Poller, :start_link,
         [
           [
             id: id,
             provider: configuration_struct.poller_spec(configuration),
             color: color,
             supervisor_pid: supervisor_pid,
             every: every || :never
           ]
         ]}
    }
  end

  defp shutdown_provider(%Controller{provider_pids: provider_pids} = state, provider_id) do
    provider_supervisor_pid = provider_supervisor(state)

    with pid when is_pid(pid) <- Map.get(provider_pids, provider_id),
         :ok <- DynamicSupervisor.terminate_child(provider_supervisor_pid, pid) do
      log(:info, state, "[#{provider_id}] shutdown")

      state
      |> calendar_server()
      |> GenServer.cast({:updated, provider_id, []})

      %Controller{state | provider_pids: Map.delete(provider_pids, provider_id)}
    else
      _ ->
        state
    end
  end

  defp start_providers(%Controller{slug: slug} = state) do
    slug
    |> Caltar.Storage.get_calendar_by_slug()
    |> Box.Result.unwrap!()
    |> Repo.preload([:providers])
    |> Map.fetch!(:providers)
    |> Enum.reduce(state, &start_provider(&2, &1))
  end

  defp restart_provider(%Controller{} = state, %Provider{id: provider_id} = provider) do
    state
    |> shutdown_provider(provider_id)
    |> start_provider(provider)
  end

  defp start_provider(
         %Controller{provider_pids: provider_ids} = state,
         %Provider{id: provider_id} = provider
       ) do
    spec = poller_child_spec(provider, state)

    {:ok, pid} =
      state
      |> provider_supervisor()
      |> DynamicSupervisor.start_child(spec)

    log(:info, state, "[#{provider_id}] started")

    %Controller{state | provider_pids: Map.put(provider_ids, provider_id, pid)}
  end

  defp subscribe(%Controller{slug: slug} = state) do
    Caltar.PubSub.subscribe("calendar:#{slug}")
    state
  end

  defp calendar_server(%Controller{supervisor_pid: supervisor_pid}) do
    Caltar.Calendar.StorageSupervisor.get_calendar_server(supervisor_pid)
  end

  defp provider_supervisor(%Controller{supervisor_pid: supervisor_pid}) do
    Caltar.Calendar.StorageSupervisor.get_calendar_provider_supervisor(supervisor_pid)
  end

  defp init_state(args) do
    slug = Keyword.fetch!(args, :slug)
    supervisor_pid = Keyword.fetch!(args, :supervisor_pid)

    %Controller{
      slug: slug,
      supervisor_pid: supervisor_pid
    }
  end

  defp log(:info, %Controller{} = state, message) do
    state
    |> build_message(message)
    |> Logger.info()
  end

  defp build_message(%Controller{} = state, message) do
    "[#{inspect(__MODULE__)}] [#{state.slug}] #{message}"
  end
end
