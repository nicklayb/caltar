defmodule Caltar.Calendar.Poller do
  use GenServer

  require Logger

  alias Caltar.Calendar.Event
  alias Caltar.Calendar.Poller

  defstruct [:id, :color, :provider, :supervisor_pid, :every, :state]

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    state = init_state(args)
    log(:info, state, "started")
    {:ok, state}
  end

  def handle_info(:poll, %Poller{} = poller) do
    state =
      case poll(poller) do
        {:update, new_state, events} ->
          log(:info, poller, "updated with #{length(events)} events")

          poller
          |> put_state(new_state)
          |> push_events(events)
          |> schedule_poll()

        {:update, new_state} ->
          log(:info, poller, "no events")

          poller
          |> put_state(new_state)
          |> schedule_poll()

        :nothing ->
          log(:info, poller, "no updates")
          poller
      end

    {:noreply, state}
  end

  defp poll(%Poller{provider: {provider, options}, state: state} = poller) do
    log(:info, poller, "polling...")

    case provider.poll(now(), state, options) do
      {:ok, new_state} ->
        update_state(poller, new_state)

      {:error, error} ->
        log(:error, poller, inspect(error))
        :nothing
    end
  end

  defp update_state(%Poller{provider: {provider, options}, state: old_state}, new_state) do
    provider.update(old_state, new_state, options)
  end

  defp put_state(%Poller{} = poller, new_state) do
    %Poller{poller | state: new_state}
  end

  defp push_events(%Poller{id: poller_id} = poller, events) do
    events = Enum.map(events, &tag_event(poller, &1))

    poller
    |> calendar_server()
    |> GenServer.cast({:updated, poller_id, events})

    poller
  end

  defp tag_event(%Poller{color: poller_color, id: provider_id}, %Event{color: color} = event) do
    color = color || poller_color

    %Event{event | provider: provider_id, color: color}
  end

  defp init_state(args) do
    provider =
      case Keyword.fetch!(args, :provider) do
        {provider, options} -> {provider, options}
        provider -> {provider, []}
      end

    id = Keyword.get(args, :id, Ecto.UUID.generate())
    supervisor_pid = Keyword.fetch!(args, :supervisor_pid)
    every = Keyword.fetch!(args, :every)

    color =
      Keyword.get_lazy(args, :color, fn ->
        Box.Generator.generate(Box.Generator.Color, type: :hsl, saturation: 17, lightness: 50)
      end)

    initial_poller_state = Keyword.get(args, :initial_state)

    state = %Poller{
      id: id,
      provider: provider,
      supervisor_pid: supervisor_pid,
      every: every,
      color: color,
      state: initial_poller_state
    }

    send(self(), :poll)
    state
  end

  defp schedule_poll(%Poller{every: :never} = poller) do
    poller
  end

  defp schedule_poll(%Poller{every: every} = poller) do
    Process.send_after(self(), :poll, every)
    poller
  end

  defp calendar_server(%Poller{supervisor_pid: supervisor_pid}) do
    Caltar.Calendar.StorageSupervisor.get_calendar_server(supervisor_pid)
  end

  defp now, do: Caltar.Date.now!()

  defp log(:info, %Poller{} = state, message) do
    state
    |> build_message(message)
    |> Logger.info()
  end

  defp log(:error, %Poller{} = state, message) do
    state
    |> build_message(message)
    |> Logger.error()
  end

  defp build_message(%Poller{} = state, message) do
    "[#{inspect(__MODULE__)}] [#{inspect_provider(state)}] [#{state.id}] #{message}"
  end

  defp inspect_provider(%Poller{provider: {provider, _}}), do: inspect(provider)
end
