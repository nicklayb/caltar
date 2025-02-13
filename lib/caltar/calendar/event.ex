defmodule Caltar.Calendar.Event do
  alias Caltar.Calendar.Event
  defstruct [:starts_at, :ends_at, :title, :color]

  def to_occurences(%Event{starts_at: starts_at, ends_at: ends_at} = event) do
    base_date = DateTime.to_date(starts_at)
    difference = DateTime.diff(starts_at, ends_at, :day)

    if difference <= 0 do
      %{base_date => event}
    else
      Enum.reduce(1..difference, %{}, fn shift, acc ->
        date = Date.shift(base_date, days: shift)
        Map.put(acc, date, event)
      end)
    end
  end
end
