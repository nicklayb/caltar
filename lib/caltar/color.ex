defmodule Caltar.Color do
  def random_pastel do
    hsl(saturation: 17, lightness: 50)
  end

  defp hsl(options) do
    Box.Generator.generate(Box.Generator.Color, Keyword.put(options, :type, :hsl))
  end
end
