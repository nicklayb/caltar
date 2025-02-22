defmodule Caltar.Date do
  @utc "Etc/UTC"

  def same_day?(%{year: year, month: month, day: day}, %{year: year, month: month, day: day}),
    do: true

  def same_day?(_, _), do: false

  def same_month?(%{year: year, month: month}, %{year: year, month: month}), do: true
  def same_month?(_, _), do: false

  def start_of_day?(%{hour: 0, minute: 0, second: 0}), do: true
  def start_of_day?(_), do: false

  def start_of_month(date) do
    %{date | day: 1}
  end

  def end_of_month(%{year: year, month: month} = date) do
    day = Calendar.ISO.days_in_month(year, month)

    %{date | day: day}
  end

  @start_of_week :sunday
  def weekday(%{year: year, month: month, day: day}) do
    {day, _, _} = Calendar.ISO.day_of_week(year, month, day, @start_of_week)
    day - 1
  end

  def to_string!(date, options) do
    Caltar.Cldr.DateTime.to_string!(
      date,
      Keyword.put_new(options, :locale, Caltar.Application.locale())
    )
  end

  def date_time_from_date(%Date{} = date, %Time{} = time \\ Time.new!(0, 0, 0)) do
    DateTime.new!(date, time, timezone())
  end

  @week [
    ~D[2025-01-05],
    ~D[2025-01-06],
    ~D[2025-01-07],
    ~D[2025-01-08],
    ~D[2025-01-09],
    ~D[2025-01-10],
    ~D[2025-01-11]
  ]
  def week, do: @week

  def shift_timezone!(%DateTime{} = date_time) do
    DateTime.shift_zone!(date_time, timezone())
  end

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
