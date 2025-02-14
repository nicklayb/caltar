defmodule CaltarWeb.Main.Live do
  alias Caltar.Calendar
  use CaltarWeb, :live_view

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:clock, Caltar.Date.now!())
      |> assign(:calendar, Calendar.build(Caltar.Date.now!()))
      |> subscribe("clock")

    {:ok, socket}
  end

  def handle_pubsub(
        %Box.PubSub.Message{topic: "clock", message: :updated, params: new_clock},
        socket
      ) do
    socket = assign(socket, :clock, new_clock)
    {:noreply, socket}
  end
end
