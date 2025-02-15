defmodule CaltarWeb.Components.Calendar do
  use CaltarWeb, :component

  alias Caltar.Calendar

  def render(assigns) do
    ~H"""
    <div class="bordser bosrder-blue">
      <.header />
      <%= for week <- @calendar.dates do %>
        <.week calendar={@calendar} week={week} />
      <% end %>
    </div>
    """
  end

  defp header(assigns) do
    assigns =
      assign(
        assigns,
        :header_week,
        Enum.map(Caltar.Date.week(), &Caltar.Date.to_string!(&1, format: "EEEE"))
      )

    ~H"""
    <div class="flex">
      <%= for day <- @header_week do %>
        <div class="flex flex-1 justify-center">{day}</div>
      <% end %>
    </div>
    """
  end

  defp week(%{calendar: calendar, week: week} = assigns) do
    assigns = assign(assigns, :current_week?, Calendar.current_week?(calendar, week))

    ~H"""
      <div class="flex bsorder-b last:bsorder-0">
        <%= for day <- @week do %>
          <.day calendar={@calendar} day={day} current_week?={@current_week?}/>
        <% end %>
      </div>
    """
  end

  defp day(%{calendar: calendar, day: day} = assigns) do
    assigns =
      assigns
      |> assign(:current_day?, Calendar.current_day?(calendar, day))
      |> assign(:current_month?, Calendar.current_month?(calendar, day))
      |> assign(:events, Calendar.events_for_date(calendar, day))

    ~H"""
      <div class="flex flex-col flex-1 border m-0.5 rounded-sm">
        <div class={Html.class("pl-2 py-1 text-sm border-b", [{@current_day?, "font-bold"}, {not @current_month?, "text-gray-500"}])}>
          {@day.day}
        </div>
        <div class={Html.class({@current_week?, "h-96", "h-24"})}>
          <%= for event <- @events do %>
            <div><%= event.title %></div>
          <% end %>
        </div>
      </div>
    """
  end
end
