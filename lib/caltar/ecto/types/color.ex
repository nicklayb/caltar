defmodule Caltar.Ecto.Types.Color do
  alias Box.Color
  use Ecto.Type

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
    raw
    |> Map.update!("value", &load_value/1)
    |> Map.update!("format", &String.to_existing_atom/1)
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      Map.put(acc, String.to_existing_atom(key), value)
    end)
    |> then(&struct!(Color, &1))
    |> Box.Result.succeed()
  end

  def dump(%Color{} = color) do
    color
    |> Map.from_struct()
    |> Map.update!(:value, &dump_value/1)
    |> Map.update!(:format, &to_string/1)
    |> Box.Result.succeed()
  end

  def dump(_), do: :error

  defp load_value([first, second, third]), do: {first, second, third}

  defp dump_value({first, second, third}), do: [first, second, third]
end

defimpl Phoenix.HTML.Safe, for: Box.Color do
  def to_iodata(%Box.Color{} = color) do
    Box.Color.to_css(color)
  end
end

defimpl String.Chars, for: Box.Color do
  def to_string(%Box.Color{} = color) do
    Box.Color.to_css(color)
  end
end
