defmodule CaltarWeb.Components.Calendar do
  use CaltarWeb, :component

  alias Caltar.Calendar

  def render(assigns) do
    ~H"""
    <%= for week <- @calendar.dates do %>
      <.week calendar={@calendar} week={week} />
    <% end %>
    """
  end

  defp week(%{calendar: calendar, week: week} = assigns) do
    assigns = assign(assigns, :current_week?, Calendar.current_week?(calendar, week))

    ~H"""
      <div class={Html.class("flex", {@current_week?, "bg-red-100"})}>
        <%= for day <- @week do %>
          <.day calendar={@calendar} day={day} />
        <% end %>
      </div>
    """
  end

  defp day(%{calendar: calendar, day: day} = assigns) do
    assigns =
      assigns
      |> assign(:current_day?, Calendar.current_day?(calendar, day))
      |> assign(:current_month?, Calendar.current_month?(calendar, day))

    ~H"""
      <div class={Html.class("flex flex-1", [{@current_day?, "font-bold"}, {not @current_month?, "text-gray-500"}])}>
        {@day.day}
      </div>
    """
  end
end
