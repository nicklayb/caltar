defmodule Caltar.Calendar.Builder do
  @moduledoc """
  Builds a month calendar from a given date.
  """
  @days_in_week 7
  @type date :: DateTime.t()
  @type calendar :: [week()]
  @type week :: [date()]

  @doc """
  Build the month calendar for the given date. It also pads days before and after the given month to give a full 7-day per week list of list of date.
  """
  @spec build_month(DateTime.t() | Date.t()) :: %{
          days: calendar(),
          start_date: date(),
          end_date: date()
        }
  def build_month(%DateTime{} = current_date) do
    current_date
    |> DateTime.to_date()
    |> build_month()
  end

  def build_month(%Date{} = current_date) do
    start_date = Caltar.Date.start_of_month(current_date)
    end_date = Caltar.Date.end_of_month(current_date)

    start_date
    |> build_month(end_date, %{days: [], start_date: start_date, end_date: end_date})
    |> pad_start()
    |> pad_end()
    |> Map.update!(:days, &Enum.chunk_every(&1, @days_in_week))
  end

  defp build_month(
         %{month: month} = current_date,
         %{month: month} = end_date,
         acc
       ) do
    acc = Map.update!(acc, :days, &(&1 ++ [current_date]))

    current_date
    |> Date.shift(day: 1)
    |> build_month(end_date, acc)
  end

  defp build_month(_, _, acc), do: acc

  defp pad_start(%{days: [start | _]} = acc) do
    weekday =
      start
      |> Caltar.Date.weekday()
      |> next_weekday()

    if weekday > 1 do
      range = 1..(weekday - 1)
      pad = Enum.map(range, fn day -> Date.shift(start, day: -(weekday - day)) end)

      acc
      |> Map.update!(:days, &(pad ++ &1))
      |> Map.put(:start_date, List.first(pad))
    else
      acc
    end
  end

  defp pad_end(%{days: month} = acc) do
    end_date = List.last(month)
    weekday = Caltar.Date.weekday(end_date) + 1
    diff = @days_in_week - weekday

    if diff > 0 do
      range = 1..diff
      pad = Enum.map(range, fn day -> Date.shift(end_date, day: day) end)

      acc
      |> Map.update!(:days, &(&1 ++ pad))
      |> Map.put(:end_date, List.last(pad))
    else
      acc
    end
  end

  defp next_weekday(7), do: 1
  defp next_weekday(weekday), do: weekday + 1
end
