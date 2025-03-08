defmodule Caltar.Storage.Calendar.DisplayMode do
  @behaviour Box.Ecto.DynamicType

  def encode(:current_month), do: {:ok, "current_month"}
  def encode({:relative, left}), do: {:ok, "relative:#{left}"}
  def encode({:relative, left, right}), do: {:ok, "relative:#{left}:#{right}"}

  def encode(_), do: :error

  def decode("current_month"), do: {:ok, :current_month}

  def decode("relative:" <> range) do
    case Regex.scan(~r/([0-9]+)(:([0-9]+))?/, range) do
      [[_, left, _, right]] ->
        {:ok, {:relative, String.to_integer(left), String.to_integer(right)}}

      [[_, value]] ->
        {:ok, {:relative, String.to_integer(value)}}

      _ ->
        :error
    end
  end

  def decode(_), do: :error
end
