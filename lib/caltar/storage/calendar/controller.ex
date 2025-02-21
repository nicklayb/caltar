defmodule Caltar.Calendar.Controller do
  use GenServer

  require Logger

  alias Caltar.Calendar.Controller

  defstruct [:slug, :supervisor_pid]

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    state =
      args
      |> init_state()
      |> subscribe()

    log(:info, state, "started")

    {:ok, state}
  end

  def handle_info(%Box.PubSub.Message{message: :calendar_updated}, state) do
    log(:info, state, "updated")
    shutdown_supervisor(state)
    {:noreply, state}
  end

  defp subscribe(%Controller{slug: slug} = state) do
    Caltar.PubSub.subscribe("calendar:#{slug}")
    state
  end

  defp shutdown_supervisor(%Controller{supervisor_pid: supervisor_pid} = state) do
    Supervisor.stop(supervisor_pid, :normal)
    state
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

  defp log(:error, %Controller{} = state, message) do
    state
    |> build_message(message)
    |> Logger.error()
  end

  defp build_message(%Controller{} = state, message) do
    "[#{inspect(__MODULE__)}] [#{state.slug}] #{message}"
  end
end
