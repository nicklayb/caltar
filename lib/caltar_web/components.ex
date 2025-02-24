defmodule CaltarWeb.Components do
  alias Phoenix.LiveView.AsyncResult
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

  slot(:inner_block)

  def empty(assigns) do
    ~H"""
    <div class="w-full py-5 text-center bg-gray-900 text-gray-600">
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr(:class, :string, default: "")
  slot(:inner_block)

  def h1(assigns) do
    ~H"""
    <h1 class={Html.class("text-4xl my-8", @class)}>{render_slot(@inner_block)}</h1>
    """
  end

  attr(:class, :string, default: "")
  slot(:inner_block)

  def h2(assigns) do
    ~H"""
    <h2 class={Html.class("text-3xl my-6 text-gray-400", @class)}>{render_slot(@inner_block)}</h2>
    """
  end

  attr(:class, :string, default: "")
  slot(:inner_block)

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
        <div class="flex items-center w-full">{render_slot(@header)}</div>
      </div>
      <%= if @expanded do %>
        <div class="p-4 border-t border-gray-600">{render_slot(@body)}</div>
      <% end %>
    </div>
    """
  end

  attr(:class, :string, default: "border-indigo-400 bg-indigo-300 text-indigo-800")
  slot(:inner_block)

  def tag(assigns) do
    ~H"""
    <div class={Html.class("block rounded-md border text-sm px-1 pb-0.5", @class)}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr(:class, :string, default: "")
  attr(:color, Box.Color, required: true)

  def pastille(assigns) do
    ~H"""
    <div
      class={Html.class("border w-6 h-6 rounded-full", @class)}
      style={"background-color: #{@color}"}
    >
    </div>
    """
  end

  attr(:loading, :boolean, required: true)
  slot(:inner_block)

  def loading(assigns) do
    ~H"""
    <%= if @loading do %>
      <Components.Icon.icon icon={:loading} />
    <% else %>
      {render_slot(@inner_block)}
    <% end %>
    """
  end

  attr(:async_result, AsyncResult, required: true)

  slot(:result, required: true)
  slot(:error, required: true)

  def result(assigns) do
    ~H"""
    <.loading loading={@async_result.loading}>
      <%= case @async_result do %>
        <% %AsyncResult{ok?: true, result: result} -> %>
          {render_slot(@result, result)}
        <% %AsyncResult{ok?: false, failed: failed} -> %>
          {render_slot(@error, failed)}
      <% end %>
    </.loading>
    """
  end
end
