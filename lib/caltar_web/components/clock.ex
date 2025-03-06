defmodule CaltarWeb.Components.Clock do
  use CaltarWeb, :component

  def render(assigns) do
    ~H"""
    <div class="flex text-7xl" id="clock" phx-hook="Clock">
      <.number value={@clock.hour} />
      <.colon />
      <.number value={@clock.minute} />
      <.colon />
      <.number value={@clock.second} />
    </div>
    """
  end

  defp number(assigns) do
    assigns = update(assigns, :value, &String.pad_leading(to_string(&1), 2, "0"))

    ~H"""
    <div class="">{@value}</div>
    """
  end

  defp colon(assigns) do
    ~H"""
    <div class="text-gray-600">:</div>
    """
  end
end
