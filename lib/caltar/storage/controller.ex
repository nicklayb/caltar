defmodule Caltar.Storage.Controller do
  alias Caltar.Calendar.StorageSupervisor
  alias Caltar.Storage.Calendar
  use GenServer

  require Logger

  @name Caltar.Storage.Controller

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: @name)
  end

  def init(_) do
    Caltar.PubSub.subscribe("calendars")
    {:ok, nil}
  end

  def handle_info(%Box.PubSub.Message{message: :updated, params: %Calendar{id: id}}, socket) do
    Logger.info("[#{inspect(__MODULE__)}] [handle_info] [#{id}] updated, restarting")

    {Caltar.Storage.Calendar.Supervisor, id}
    |> StorageSupervisor.registry_name()
    |> Supervisor.stop()

    {:noreply, socket}
  end

  def handle_info(%Box.PubSub.Message{message: message}, socket) do
    Logger.debug("[#{inspect(__MODULE__)}] [handle_info] #{inspect(message)}")
    {:noreply, socket}
  end
end
