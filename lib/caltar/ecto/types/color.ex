defmodule Caltar.Ecto.Types.Color do
  use Ecto.Type

  alias Box.Color

  def type, do: :map

  def cast(string) when is_binary(string) do
    color = Color.parse!(string)
    {:ok, color}
  rescue
    _ ->
      :error
  end

  def cast(%Color{} = color), do: {:ok, color}

  def cast(_), do: :error

  def load(hex) when is_binary(hex) do
    hex
    |> Color.parse!()
    |> Box.Result.succeed()
  end

  def load(raw) when is_map(raw) do
    color = %Color{
      alpha: get_from_map!(raw, :alpha),
      format: get_from_map!(raw, :format),
      value: get_from_map!(raw, :value),
      source: get_from_map!(raw, :source)
    }

    {:ok, color}
  end

  defp get_from_map!(map, field) do
    map
    |> Map.fetch!(to_string(field))
    |> then(&load_value(field, &1))
  end

  def dump(%Color{} = color) do
    color
    |> Map.from_struct()
    |> Map.update!(:value, &dump_value(:value, &1))
    |> Map.update!(:format, &dump_value(:format, &1))
    |> Box.Result.succeed()
  end

  def dump(_), do: :error

  defp load_value(:value, [first, second, third]), do: {first, second, third}

  defp load_value(_, "hsl"), do: :hsl
  defp load_value(_, "rgb"), do: :rgb
  defp load_value(_, "hex"), do: :hex

  defp load_value(_, value), do: value

  defp dump_value(:value, {first, second, third}), do: [first, second, third]

  defp dump_value(:format, format), do: to_string(format)

  defp dump_value(_, value), do: value
end

defimpl Phoenix.HTML.Safe, for: Box.Color do
  def to_iodata(%Box.Color{source: source} = color) do
    output = Box.Color.to_css(color)

    case source do
      :hex -> "#" <> output
      _ -> output
    end
  end
end

defimpl String.Chars, for: Box.Color do
  def to_string(%Box.Color{source: source} = color) do
    output = Box.Color.to_css(color)

    case source do
      :hex -> "#" <> output
      _ -> output
    end
  end
end
