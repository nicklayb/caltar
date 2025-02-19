defmodule Caltar.Clock do
  use GenServer

  alias Caltar.Clock

  defstruct [:time]

  def start_link(args) do
    GenServer.start_link(Caltar.Clock, args, name: Keyword.get(args, :name, Caltar.Clock))
  end

  def init(_args) do
    state = tick(%Clock{time: now()})
    {:ok, state}
  end

  def handle_info(:tick, %Clock{} = clock) do
    state =
      clock
      |> update_clock()
      |> tick()

    {:noreply, state}
  end

  @tick_timer 100
  defp tick(%Clock{} = clock) do
    Process.send_after(self(), :tick, @tick_timer)
    clock
  end

  defp update_clock(%Clock{} = clock) do
    updated_time = now()

    case updated_parts(clock, updated_time) do
      [] ->
        clock

      parts ->
        clock
        |> put_time(updated_time)
        |> broadcast_parts_updated(parts)
    end
  end

  defp broadcast_parts_updated(%Clock{time: time} = clock, parts) do
    Enum.each(parts, fn part ->
      Caltar.PubSub.broadcast("clock:#{to_string(part)}", {:updated, time})
    end)

    clock
  end

  @checked_parts ~w(second minute hour day month year)a
  defp updated_parts(%Clock{time: current_time}, new_time) do
    Enum.filter(@checked_parts, fn key ->
      Map.fetch!(current_time, key) != Map.fetch!(new_time, key)
    end)
  end

  defp put_time(%Clock{} = clock, new_time) do
    %Clock{clock | time: new_time}
  end

  defp now, do: Caltar.Date.now!()
end
