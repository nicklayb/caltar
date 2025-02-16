defmodule Caltar.Factory do
  use Caltar.Factory.Calendar

  def build(factory, attributes) do
    factory
    |> build()
    |> struct!(attributes)
  end

  def generate(:chars, options), do: generate(Box.Generator.Characters, options)
  def generate(:alpha, options), do: generate(Box.Generator.Alphanumerical, options)
  def generate(:base64, options), do: generate(Box.Generator.Base64, options)
  def generate(:hex, options), do: generate(Box.Generator.Hexadecimal, options)

  def generate(generator, options) do
    Box.Generator.generate(generator, options)
  end

  def sequence(key) do
    previous = Process.get({:sequence, key}) || 0
    new = previous + 1
    Process.put({:sequence, key}, new)
    new
  end
end
