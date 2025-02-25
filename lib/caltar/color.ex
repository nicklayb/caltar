defmodule Caltar.Color do
  def random_pastel(type \\ :hsl)

  def random_pastel(:hsl) do
    hsl(saturation: 17, lightness: 50)
  end

  @low_color_range 80..255
  def random_pastel(:hex) do
    color = hex(red: @low_color_range, blue: @low_color_range, green: @low_color_range)
    %Box.Color{color | source: :hex}
  end

  defp hex(options) do
    Box.Generator.generate(Box.Generator.Color, Keyword.put(options, :type, :rgb))
  end

  defp hsl(options) do
    Box.Generator.generate(Box.Generator.Color, Keyword.put(options, :type, :hsl))
  end
end
