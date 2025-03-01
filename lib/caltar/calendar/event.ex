defmodule Caltar.Calendar.Event do
  alias Caltar.Calendar.Event

  defstruct [
    :id,
    :provider,
    :source,
    :starts_at,
    :ends_at,
    :title,
    :color,
    :priority,
    params: %{}
  ]

  @type t :: %Event{
          id: String.t(),
          provider: tuple() | atom(),
          source: atom(),
          starts_at: DateTime.t(),
          ends_at: DateTime.t(),
          title: String.t(),
          color: String.t(),
          priority: integer(),
          params: map()
        }

  def compare(%Event{starts_at: left_starts_at}, %Event{starts_at: right_starts_at}) do
    DateTime.compare(left_starts_at, right_starts_at)
  end

  def full_day?(%Event{starts_at: starts_at, ends_at: ends_at}), do: starts_at == ends_at

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
