defmodule CaltarWeb.Components.Calendar do
  use CaltarWeb, :component

  alias Caltar.Calendar
  alias Caltar.Calendar.Marker
  alias Caltar.Calendar.Provider.Icalendar, as: IcalendarProvider
  alias Caltar.Calendar.Provider.Sport, as: SportProvider
  alias Caltar.Storage.Configuration

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
        <.day calendar={@calendar} day={day} current_week?={@current_week?} />
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
      |> assign(:markers, Calendar.markers_for_date(calendar, day))
      |> assign(:max_visible_events, @max_visible_events)

    ~H"""
    <div class={
      Html.class("flex flex-col overflow-hidden flex-1 border m-0.5 rounded-sm", [
        {not @current_month?, "opacity-50"},
        {@current_day?, "border-pink-600", "border-gray-700"}
      ])
    }>
      <div class={
        Html.class(
          "pl-2 py-1 bg-gray-800 text-white text-sm flex flex-row items-center justify-between",
          [
            {@current_day?, "bg-pink-700 text-white border-b-pink-700 font-bold"}
          ]
        )
      }>
        <span>{@day.day}</span>
        <span class="flex">
          <%= for %Marker{icon: icon} <- @markers do %>
            <Components.Icon.icon icon={icon} width={16} height={16} class="mr-1" />
          <% end %>
        </span>
      </div>
      <div class="p-1 h-32">
        <%= with {visible, overflow} <- Enum.split(@events, @max_visible_events) do %>
          <%= for event <- visible do %>
            <.event event={event} />
          <% end %>
          <%= if Enum.any?(overflow) do %>
            <div class="text-right pr-2">{gettext("+%{count} more", count: length(overflow))}</div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  defp event(
         %{
           event: %Calendar.Event{
             starts_at: starts_at,
             title: title,
             params: %SportProvider.EventParams{
               progress: %SportProvider.EventParams.Progress{status: status}
             }
           }
         } = assigns
       ) do
    assigns =
      assigns
      |> assign(:start_time, Caltar.Date.to_string!(starts_at, format: "H:mm"))
      |> assign(:status, status)
      |> assign(:title, Regex.replace(~r/[A-Z]+ - /, title, ""))

    ~H"""
    <div class="mb-1 flex overflow-hidden rounded-sm text-sm text-gray-800">
      <%= case @status do %>
        <% :pending -> %>
          <.sport_event_scores home={@event.params.home} away={@event.params.away} logo_size="w-6">
            <div class="text-white text-md flex flex-col items-center justify-center">
              {@start_time}
            </div>
          </.sport_event_scores>
        <% :finished -> %>
          <.sport_event_scores home={@event.params.home} away={@event.params.away} logo_size="w-6">
            <div class="text-white text-md flex flex-col items-center"></div>
          </.sport_event_scores>
        <% _ -> %>
          <.sport_event_scores home={@event.params.home} away={@event.params.away} logo_size="w-8">
            <div class="text-white text-md flex flex-col items-center">
              <span class="text-xs">{@event.params.progress.clock}</span>
              <span class="text-xs">{@event.params.progress.clock_status}</span>
            </div>
          </.sport_event_scores>
      <% end %>
    </div>
    """
  end

  defp event(%{event: %Calendar.Event{color: color, params: params}} = assigns) do
    color =
      case params do
        %IcalendarProvider.Formula1Params{} -> "#FFFFFF"
        _ -> color
      end

    assigns = assign(assigns, :color, color)

    ~H"""
    <.standard_event event={@event} color={@color}>
      <%= case @event.params do %>
        <% %IcalendarProvider.Formula1Params{short_name: short_name, country_code: country_code} -> %>
          <div class="flex items-center justify-between">
            <img
              src="https://upload.wikimedia.org/wikipedia/commons/f/f2/New_era_F1_logo.png"
              class="h-3"
            />
            {short_name}
            <img src={"https://flagsapi.com/#{country_code}/flat/64.png"} class="h-6" />
          </div>
        <% %IcalendarProvider.Params{icon: icon} -> %>
          <div class="flex">
            <img src={icon} class="h-2" />
            {@event.title}
          </div>
        <% _ -> %>
          {@event.title}
      <% end %>
    </.standard_event>
    """
  end

  defp standard_event(%{event: %Calendar.Event{starts_at: starts_at} = event} = assigns) do
    start_time =
      starts_at
      |> Caltar.Date.to_string!(format: "H:mm")
      |> String.pad_leading(5, "0")

    assigns =
      assigns
      |> assign(:start_time, start_time)
      |> assign(:full_day?, Calendar.Event.full_day?(event))

    ~H"""
    <div class="mb-1 flex overflow-hidden rounded-sm text-sm text-gray-800">
      <%= if not @full_day? do %>
        <div class="py-0.5 px-1 bg-white font-bold" style={"background-color: #{@color};"}>
          {String.pad_leading(@start_time, 5, "0")}
        </div>
      <% end %>
      <div
        class="p-0.5 pl-1 max-h-[3.2em] w-full brightness-125"
        style={"background-color: #{@color};"}
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  defp sport_event_scores(assigns) do
    ~H"""
    <div class="flex justify-between w-full">
      <div class="flex items-center">
        <img class={@logo_size} src={@away.avatar} />
        <span class="text-white text-lg">{@away.score}</span>
      </div>
      {render_slot(@inner_block)}
      <div class="flex items-center">
        <span class="text-white text-lg">{@home.score}</span>
        <img class={@logo_size} src={@home.avatar} />
      </div>
    </div>
    """
  end
end
