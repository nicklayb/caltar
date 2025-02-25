defmodule CaltarWeb.Hooks.WithModal do
  def on_mount(:default, _params, _session, socket) do
    socket =
      socket
      |> Phoenix.LiveView.attach_hook(:handle_close_modal_event, :handle_event, &handle_event/3)
      |> Phoenix.LiveView.attach_hook(:handle_close_modal_message, :handle_info, &handle_info/2)
      |> close_modal()

    {:cont, socket}
  end

  defp handle_info(:close_modal, %Phoenix.LiveView.Socket{} = socket) do
    socket = close_modal(socket)
    {:halt, socket}
  end

  defp handle_info(_other_message, %Phoenix.LiveView.Socket{} = socket) do
    {:cont, socket}
  end

  defp handle_event("modal:close", _, socket) do
    socket = close_modal(socket)
    {:halt, socket}
  end

  defp handle_event("modal:keyup", %{"key" => "Escape"}, %{assigns: %{modal: modal}} = socket)
       when not is_nil(modal) do
    socket = close_modal(socket)

    {:halt, socket}
  end

  defp handle_event("modal:keyup", _, socket) do
    {:halt, socket}
  end

  defp handle_event(_, _, socket) do
    {:cont, socket}
  end

  defp close_modal(socket) do
    Phoenix.Component.assign(socket, :modal, nil)
  end
end
