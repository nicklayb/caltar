defmodule Caltar.Calendar.Server do
  alias Caltar.Calendar
  use GenServer

  @name Caltar.Calendar.Server
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: Keyword.get(args, :name, @name))
  end

  def init(_) do
    calendar = Calendar.build(Caltar.Date.now!())
    {:ok, %{calendar: calendar}}
  end

  def handle_info(%Box.PubSub.Message{topic: "calendar", message: :new_events, params: []}, state) do
    {:noreply, state}
  end

  def handle_info(%Box.PubSub.Message{topic: "calendar", message: :new_events, params: events}) do
  end
end
