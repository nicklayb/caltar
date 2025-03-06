defmodule CaltarWeb.Calendar.Live do
  use CaltarWeb, :live_view

  def mount(params, _session, socket) do
    calendar_slug = Map.get(params, "slug", "main")

    socket =
      socket
      |> assign(:clock, Caltar.Date.now!())
      |> assign(:calendar, Caltar.Calendar.Server.get_calendar_by_slug(calendar_slug))
      |> subscribe("clock:hour")
      |> subscribe("calendar:#{calendar_slug}")

    {:ok, socket}
  end

  def handle_pubsub(
        %Box.PubSub.Message{topic: "clock:hour", message: :updated, params: new_clock},
        socket
      ) do
    socket = assign(socket, :clock, new_clock)
    {:noreply, socket}
  end

  def handle_pubsub(
        %Box.PubSub.Message{topic: "calendar:" <> _, message: :updated, params: new_calendar},
        socket
      ) do
    socket = assign(socket, :calendar, new_calendar)
    {:noreply, socket}
  end
end
