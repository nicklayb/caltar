defmodule Caltar.CalendarTest do
  use Caltar.BaseCase
  alias Caltar.Calendar
  @default_date ~U[2025-01-04 08:10:00Z]

  setup [:create_calendar]

  describe "build/1" do
    test "builds a calendar", %{input_date: input_date} do
      assert %Calendar{
               dates: [
                 [
                   ~D[2024-12-29],
                   ~D[2024-12-30],
                   ~D[2024-12-31],
                   ~D[2025-01-01],
                   ~D[2025-01-02],
                   ~D[2025-01-03],
                   ~D[2025-01-04]
                 ],
                 [
                   ~D[2025-01-05],
                   ~D[2025-01-06],
                   ~D[2025-01-07],
                   ~D[2025-01-08],
                   ~D[2025-01-09],
                   ~D[2025-01-10],
                   ~D[2025-01-11]
                 ],
                 [
                   ~D[2025-01-12],
                   ~D[2025-01-13],
                   ~D[2025-01-14],
                   ~D[2025-01-15],
                   ~D[2025-01-16],
                   ~D[2025-01-17],
                   ~D[2025-01-18]
                 ],
                 [
                   ~D[2025-01-19],
                   ~D[2025-01-20],
                   ~D[2025-01-21],
                   ~D[2025-01-22],
                   ~D[2025-01-23],
                   ~D[2025-01-24],
                   ~D[2025-01-25]
                 ],
                 [
                   ~D[2025-01-26],
                   ~D[2025-01-27],
                   ~D[2025-01-28],
                   ~D[2025-01-29],
                   ~D[2025-01-30],
                   ~D[2025-01-31],
                   ~D[2025-02-01]
                 ]
               ],
               start_date: ~D[2024-12-29],
               end_date: ~D[2025-02-01],
               current_time: ^input_date,
               events: %{}
             } =
               Calendar.build(input_date)
    end
  end

  describe "events_for_date/2" do
    @tag events: [
           build(:calendar_event,
             id: "test1",
             starts_at: ~U[2025-01-18 10:00:00Z],
             ends_at: ~U[2025-01-18 12:00:00Z]
           ),
           build(:calendar_event,
             id: "test2",
             starts_at: ~U[2025-01-10 20:00:00Z],
             ends_at: ~U[2025-01-11 02:00:00Z]
           ),
           build(:calendar_event,
             id: "out_of_calendar",
             starts_at: ~U[2024-01-10 20:00:00Z],
             ends_at: ~U[2024-01-11 02:00:00Z]
           )
         ]
    test "gets events for a given date", %{calendar: calendar} do
      assert [%Calendar.Event{id: "test1"}] = Calendar.events_for_date(calendar, ~D[2025-01-18])
      assert [%Calendar.Event{id: "test2"}] = Calendar.events_for_date(calendar, ~D[2025-01-10])
      assert [%Calendar.Event{id: "test2"}] = Calendar.events_for_date(calendar, ~D[2025-01-11])

      refute calendar.dates
             |> List.flatten()
             |> Enum.any?(fn date ->
               calendar
               |> Calendar.events_for_date(date)
               |> Enum.filter(&(&1.id == "out_of_calendar"))
               |> Enum.any?()
             end)
    end
  end

  defp create_calendar(context) do
    input_date = Map.get(context, :input_date, @default_date)
    events = Map.get(context, :events, [])

    calendar =
      input_date
      |> Calendar.build()
      |> Calendar.put_events(events)

    [input_date: input_date, calendar: calendar, events: events]
  end
end
