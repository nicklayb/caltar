defmodule CaltarWeb.Main.Live do
  use CaltarWeb, :live_view

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:clock, Caltar.Date.now!())
      |> assign(:calendar, Caltar.Calendar.Server.get_calendar())
      |> subscribe("clock:second")
      |> subscribe("calendar")

    {:ok, socket}
  end

  def handle_pubsub(
        %Box.PubSub.Message{topic: "clock:second", message: :updated, params: new_clock},
        socket
      ) do
    socket = assign(socket, :clock, new_clock)
    {:noreply, socket}
  end

  def handle_pubsub(
        %Box.PubSub.Message{topic: "calendar", message: :updated, params: new_calendar},
        socket
      ) do
    socket = assign(socket, :calendar, new_calendar)
    {:noreply, socket}
  end
end
