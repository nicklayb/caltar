defmodule CaltarWeb.Components.Calendar do
  use CaltarWeb, :component

  alias Caltar.Calendar

  def render(assigns) do
    ~H"""
    <div>
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
      <div class="flex">
        <%= for day <- @week do %>
          <.day calendar={@calendar} day={day} current_week?={@current_week?}/>
        <% end %>
      </div>
    """
  end

  @max_visible_events 3
  defp day(%{calendar: calendar, day: day} = assigns) do
    assigns =
      assigns
      |> assign(:current_day?, Calendar.current_day?(calendar, day))
      |> assign(:current_month?, Calendar.current_month?(calendar, day))
      |> assign(:events, Calendar.events_for_date(calendar, day))
      |> assign(:max_visible_events, @max_visible_events)

    ~H"""
      <div class={Html.class("flex flex-col overflow-hidden flex-1 border m-0.5 rounded-sm", [{not @current_month?, "opacity-50"}, {@current_day?, "text-pink-500 border-pink-600"}])}>
        <div class={Html.class("pl-2 py-1 bg-gray-800 text-white text-sm border-b", [{@current_day?, "bg-pink-500 text-white border-b-pink-500"}])}>
          {@day.day}
        </div>
        <div class="p-1 h-32">
          <%= with {visible, overflow} <- Enum.split(@events, @max_visible_events) do %>
            <%= for event <- visible do %>
              <.event event={event} />
            <% end %>
            <%= if Enum.any?(overflow) do %>
              <%= gettext("+%{count} more", count: length(overflow)) %>
            <% end %>
          <% end %>
        </div>
      </div>
    """
  end

  defp event(%{event: %Calendar.Event{starts_at: starts_at}} = assigns) do
    assigns = assign(assigns, :start_time, Caltar.Date.to_string!(starts_at, format: "H:mm"))

    ~H"""
      <div class="mb-1 flex overflow-hidden rounded-sm text-sm text-gray-800">
        <div class="py-0.5 px-1 bg-white font-bold" style={"background-color: #{@event.color};"}><%= String.pad_leading(@start_time, 5, "0") %></div>
        <div class="p-0.5 pl-1 truncate line-clamp-1 w-full brightness-125" style={"background-color: #{@event.color};"}><%= @event.title %></div>
      </div>
    """
  end
end
