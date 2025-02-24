defmodule CaltarWeb.Settings.Calendar.Provider do
  use CaltarWeb, :component

  def configuration(%{configuration: configuration} = assigns) do
    assigns = assign(assigns, :properties, configuration_properties(configuration))

    ~H"""
    <table>
      <tbody>
        <%= for {title, value} <- @properties do %>
          <tr>
            <td class="pr-4">{title} :</td>
            <td class="font-mono text-pink-600">{inspect(value)}</td>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end

  @rejected_properties ~w(id)a
  defp configuration_properties(%_{} = configuration) do
    configuration
    |> Map.from_struct()
    |> Enum.reject(fn {key, _} -> key in @rejected_properties end)
    |> Enum.reduce([], fn {key, value}, acc ->
      [{Html.titleize(key), value} | acc]
    end)
    |> Enum.sort(fn {left, _}, {right, _} -> left < right end)
  end
end
