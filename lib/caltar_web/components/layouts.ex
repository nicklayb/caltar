defmodule CaltarWeb.Components.Layouts do
  use CaltarWeb, :component

  alias Caltar.Storage
  alias Caltar.Storage.Calendar

  embed_templates("layouts/*")

  @default "flex flex-col bg-gray-200 border-l-4 py-3 px-2 mb-2 rounded-r-md"
  @class %{
    info: "#{@default} border-yellow-600 text-gray-800",
    error: "#{@default} border-red-800 text-gray-800"
  }
  attr(:message, :string, required: true)
  attr(:type, :atom, required: true)

  def message(%{type: type} = assigns) do
    assigns = assign(assigns, :class, Map.fetch!(@class, type))

    ~H"""
    <%= if @message do %>
      <div class={@class}>
        <%= for message <- List.wrap(@message) do %>
          <span class="">{message}</span>
        <% end %>
      </div>
    <% end %>
    """
  end

  def nav_items(assigns) do
    assigns = assign(assigns, :nav_items, build_nav())

    ~H"""
    <%= for %{title: section_title, items: items} <- @nav_items do %>
      <span class="text-sm text-gray-600 pl-2 py-0.5 mt-2 uppercase">{section_title}</span>
      <%= for %{title: link_title, href: href, key: key} <- items do %>
        <a
          class={
            Html.class("pl-2 py-2 mx-2 rounded-md", [
              {key == @page_key, "bg-gray-700", "hover:bg-gray-800"}
            ])
          }
          href={href}
        >
          {link_title}
        </a>
      <% end %>
    <% end %>
    """
  end

  defp build_nav do
    calendars =
      Enum.map(Storage.get_calendars(), fn %Calendar{slug: slug, name: name} ->
        %{
          key: {:calendar, slug},
          title: name,
          href: ~p"/settings/calendars/#{slug}"
        }
      end)

    [
      %{
        title: gettext("Settings"),
        items: [
          %{
            key: :settings,
            title: gettext("Global"),
            href: ~p"/settings"
          }
        ]
      },
      %{
        title: gettext("Calendars"),
        items: calendars
      }
    ]
  end
end
