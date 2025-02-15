defmodule Caltar.Calendar.Event do
  alias Caltar.Calendar.Event
  defstruct [:id, :starts_at, :ends_at, :title, :color]

  def to_occurences(%Event{starts_at: starts_at, ends_at: ends_at} = event) do
    base_date = DateTime.to_date(starts_at)
    ends_date = DateTime.to_date(ends_at)
    difference = Date.diff(ends_date, base_date)

    if difference <= 0 do
      %{base_date => event}
    else
      Enum.reduce(0..difference, %{}, fn shift, acc ->
        date = Date.shift(base_date, day: shift)
        Map.put(acc, date, event)
      end)
    end
  end
end
