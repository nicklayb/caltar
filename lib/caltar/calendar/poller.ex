defmodule Caltar.Calendar.Poller do
  use GenServer

  alias Caltar.Calendar.Event
  alias Caltar.Calendar.Marker
  alias Caltar.Calendar.Poller

  require Logger

  defstruct [:id, :color, :provider, :supervisor_pid, :every, :state, :update_timer]

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

        {:update, new_state} ->
          log(:debug, poller, "no events")

          put_state(poller, new_state)

        :nothing ->
          log(:debug, poller, "no updates")
          poller
      end

    {:noreply, schedule_poll(state)}
  end

  defp poll(%Poller{provider: {provider, options}, state: state} = poller) do
    log(:debug, poller, "polling...")

    case provider.poll(now(), state, options) do
      {:ok, new_state} ->
        update_state(poller, new_state)

      {:error, error} ->
        log(:error, poller, inspect(error))
        :nothing
    end
  rescue
    error ->
      log(:error, poller, "Backing off, got error: " <> inspect(error))
      {:update, backoff_poll(poller)}
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

  defp tag_event(%Poller{id: provider_id}, %Marker{} = marker) do
    %Marker{marker | provider: provider_id}
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
    schedule_poll(poller, every)
  end

  defp schedule_poll(%Poller{update_timer: update_timer} = poller, timer) do
    if update_timer, do: Process.cancel_timer(update_timer)
    Process.send_after(self(), :poll, timer)
    poller
  end

  @backoff_timer :timer.seconds(10)
  defp backoff_poll(%Poller{} = poller) do
    schedule_poll(poller, @backoff_timer)
  end

  defp calendar_server(%Poller{supervisor_pid: supervisor_pid}) do
    Caltar.Calendar.StorageSupervisor.get_calendar_server(supervisor_pid)
  end

  defp now, do: Caltar.Date.now!()

  defp log(:debug, %Poller{} = state, message) do
    state
    |> build_message(message)
    |> Logger.debug()
  end

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
