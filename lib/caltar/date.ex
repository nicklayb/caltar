defmodule Caltar.Date do
  @utc "Etc/UTC"

  def same_day?(%{year: year, month: month, day: day}, %{year: year, month: month, day: day}),
    do: true

  def same_day?(_, _), do: false

  def same_month?(%{year: year, month: month}, %{year: year, month: month}), do: true
  def same_month?(_, _), do: false

  def now! do
    DateTime.now!(timezone())
  end

  def now do
    DateTime.now(timezone())
  end

  defp timezone do
    :caltar
    |> Application.fetch_env!(Caltar.Date)
    |> Keyword.get(:timezone, @utc)
  end
end
