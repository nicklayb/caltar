defmodule CaltarWeb.Hooks.PubSubInterceptor do
  def on_mount(:default, _params, _session, socket) do
    socket =
      Phoenix.LiveView.attach_hook(socket, :intercept_pub_sub, :handle_info, &handle_info/2)

    {:cont, socket}
  end

  defp handle_info(%Box.PubSub.Message{} = message, %Phoenix.LiveView.Socket{view: view} = socket) do
    {:noreply, socket} = view.handle_pubsub(message, socket)
    {:halt, socket}
  end

  defp handle_info(_other_message, %Phoenix.LiveView.Socket{} = socket) do
    {:cont, socket}
  end
end
