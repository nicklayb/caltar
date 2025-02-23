defmodule CaltarWeb.Components do
  use CaltarWeb, :component

  def list(assigns) do
    ~H"""
    <%= if Enum.any?(@items) do %>
      <%= for item <- @items do %>
        {render_slot(@item, item)}
      <% end %>
    <% else %>
      <%= if assigns[:empty] do %>
        {render_slot(@empty)}
      <% end %>
    <% end %>
    """
  end

  def empty(assigns) do
    ~H"""
    <div class="w-full py-5 text-center bg-gray-900 text-gray-600">
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr(:class, :string, default: "")

  def h1(assigns) do
    ~H"""
    <h1 class={Html.class("text-4xl my-8", @class)}>{render_slot(@inner_block)}</h1>
    """
  end

  attr(:class, :string, default: "")

  def h2(assigns) do
    ~H"""
    <h2 class={Html.class("text-3xl my-6 text-gray-400", @class)}>{render_slot(@inner_block)}</h2>
    """
  end

  attr(:class, :string, default: "")

  def h3(assigns) do
    ~H"""
    <h3 class={Html.class("text-2xl my-2 text-gray-500", @class)}>{render_slot(@inner_block)}</h3>
    """
  end

  def collapsible(assigns) do
    ~H"""
    <div class="border border-gray-600 rounded-md mb-4">
      <div class="flex items-center bg-gray-900">
        <div phx-click={@on_click} phx-value-id={@expanded_id} class="px-2 cursor-pointer">
          <Components.Icon.icon
            icon={if @expanded, do: :down_chevron, else: :right_chevron}
            width={30}
            height={30}
          />
        </div>
        <div class="flex items-center">{render_slot(@header)}</div>
      </div>
      <%= if @expanded do %>
        <div class="p-4 border-t border-gray-600">{render_slot(@body)}</div>
      <% end %>
    </div>
    """
  end

  attr(:class, :string, default: "border-indigo-400 bg-indigo-300 text-indigo-800")

  def tag(assigns) do
    ~H"""
    <div class={Html.class("block rounded-md border text-sm px-1 pb-0.5", @class)}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr(:class, :string, default: "")

  def pastille(assigns) do
    ~H"""
    <div
      class={Html.class("border w-6 h-6 rounded-full", @class)}
      style={"background-color: #{@color}"}
    >
    </div>
    """
  end
end
