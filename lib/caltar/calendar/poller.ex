defmodule Caltar.Calendar.Poller do
  use GenServer

  alias Caltar.Calendar.Provider.UpdateResult
  alias Caltar.Calendar.StorageSupervisor
  alias Caltar.Calendar.Event
  alias Caltar.Calendar.Marker
  alias Caltar.Calendar.Poller

  require Logger

  defstruct [
    :id,
    :color,
    :provider,
    :calendar_id,
    :every,
    :state,
    :update_timer
  ]

  def child_spec(args) do
    provider_module = Keyword.fetch!(args, :module)
    provider_options = Keyword.fetch!(args, :options)
    id = Keyword.fetch!(args, :id)
    color = Keyword.get(args, :color, Caltar.Color.random_pastel())
    calendar_id = Keyword.fetch!(args, :calendar_id)
    every = Keyword.get(args, :every, :never)

    %{
      id: {__MODULE__, id},
      restart: :transient,
      start:
        {Poller, :start_link,
         [
           [
             id: id,
             provider: {provider_module, provider_options},
             color: color,
             calendar_id: calendar_id,
             every: every || :never
           ]
         ]}
    }
  end

  def start_link(args) do
    {provider_module, _} = Keyword.fetch!(args, :provider)
    id = Keyword.fetch!(args, :id)
    name = StorageSupervisor.registry_name({Poller, id, provider_module})

    GenServer.start_link(__MODULE__, args, name: name)
  end

  def init(args) do
    state = init_state(args)
    Process.flag(:trap_exit, true)
    log(:info, state, "started")
    {:ok, state}
  end

  def handle_cast(:poll, poller) do
    send(self(), :poll)
    {:noreply, poller}
  end

  def handle_info(:stop, poller) do
    {:stop, :normal, push_events(poller, [])}
  end

  def handle_info(:poll, %Poller{} = poller) do
    state =
      poller
      |> poll()
      |> then(&handle_poll_result(poller, &1))
      |> schedule_poll()

    {:noreply, state}
  end

  def terminate(reason, state) do
    log(:info, state, "shutting down with reason #{inspect(reason)}")
    push_events(state, [])
    :ok
  end

  defp handle_poll_result(poller, %UpdateResult{
         state: new_state,
         reconfigure: reconfigure,
         events: events
       }) do
    if events == :no_update do
      log(:debug, poller, "no events")
    else
      log(:info, poller, "updated with #{length(events)} events")
    end

    poller
    |> put_state(new_state)
    |> reconfigure(reconfigure)
    |> push_events(events)
  end

  defp handle_poll_result(poller, :nothing) do
    log(:debug, poller, "no updates")
    poller
  end

  defp handle_poll_result(poller, {:backoff, error}) do
    log(:error, poller, "Backing off, got error: " <> inspect(error))
    backoff_poll(poller)
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
      {:backoff, error}
  end

  defp update_state(%Poller{provider: {provider, options}, state: old_state}, new_state) do
    provider.update(old_state, new_state, options)
  end

  defp put_state(%Poller{} = poller, new_state) do
    %Poller{poller | state: new_state}
  end

  defp push_events(%Poller{} = poller, :no_update) do
    poller
  end

  defp push_events(%Poller{id: poller_id, calendar_id: calendar_id} = poller, events) do
    events = Enum.map(events, &tag_event(poller, &1))

    calendar_id
    |> StorageSupervisor.calendar_name()
    |> GenServer.cast({:updated, poller_id, events})

    poller
  end

  defp tag_event(%Poller{id: provider_id, provider: {source, _}}, %Marker{} = marker) do
    %Marker{marker | provider: provider_id, source: source}
  end

  defp tag_event(
         %Poller{color: poller_color, id: provider_id, provider: {source, _}},
         %Event{color: color} = event
       ) do
    color = color || poller_color

    %Event{event | provider: provider_id, color: color, source: source}
  end

  defp init_state(args) do
    provider = Keyword.fetch!(args, :provider)

    id = Keyword.fetch!(args, :id)
    calendar_id = Keyword.fetch!(args, :calendar_id)
    every = Keyword.fetch!(args, :every)

    color = Keyword.fetch!(args, :color)

    initial_poller_state = Keyword.get(args, :initial_state)

    state = %Poller{
      id: id,
      provider: provider,
      calendar_id: calendar_id,
      every: every,
      color: color,
      state: initial_poller_state
    }

    send(self(), :poll)
    state
  end

  defp schedule_poll(%Poller{update_timer: update_timer, every: :never} = poller) do
    if update_timer, do: Process.cancel_timer(update_timer)
    poller
  end

  defp schedule_poll(%Poller{every: every} = poller) do
    schedule_poll(poller, :timer.seconds(every))
  end

  defp schedule_poll(%Poller{update_timer: update_timer} = poller, timer) do
    if update_timer, do: Process.cancel_timer(update_timer)
    update_timer = Process.send_after(self(), :poll, timer)
    %Poller{poller | update_timer: update_timer}
  end

  defp reconfigure(%Poller{} = state, []), do: state

  defp reconfigure(%Poller{every: same} = state, [{:every, same} | rest]) do
    reconfigure(state, rest)
  end

  defp reconfigure(%Poller{} = state, [{:every, seconds} | rest]) do
    log(:debug, state, "reconfigured every #{inspect(state.every)} -> #{inspect(seconds)}")

    %Poller{state | every: seconds || :never}
    |> schedule_poll()
    |> reconfigure(rest)
  end

  defp reconfigure(%Poller{} = state, [_ | rest]) do
    reconfigure(state, rest)
  end

  @backoff_timer :timer.seconds(10)
  defp backoff_poll(%Poller{} = poller) do
    schedule_poll(poller, @backoff_timer)
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
