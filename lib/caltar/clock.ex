defmodule Caltar.Clock do
  use GenServer

  alias Caltar.Clock

  defstruct [:precision, :time]

  def start_link(args) do
    GenServer.start_link(Caltar.Clock, args, name: Keyword.get(args, :name, Caltar.Clock))
  end

  def init(args) do
    precision = Keyword.get(args, :precision, :second)
    state = tick(%Clock{precision: precision, time: now()})
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

    if time_updated?(clock, updated_time) do
      Caltar.PubSub.broadcast("clock", {:updated, updated_time})
      %Clock{clock | time: updated_time}
    else
      clock
    end
  end

  defp time_updated?(%Clock{time: current_time, precision: precision}, right) do
    case precision do
      :second ->
        abs(DateTime.diff(current_time, right, :second)) >= 1
    end
  end

  defp now, do: Caltar.Date.now!()
end
