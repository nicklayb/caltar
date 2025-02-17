defmodule Caltar.Factory.Calendar do
  defmacro __using__(_) do
    quote do
      alias Caltar.Calendar.Event

      def build(:calendar_event) do
        %Event{
          id: generate(:alpha, length: 8),
          provider: "ics",
          title: "Music Show",
          starts_at: ~U[2025-01-05 20:00:00Z],
          ends_at: ~U[2025-01-05 23:00:00Z],
          color: "#" <> generate(:hex, length: 6)
        }
      end
    end
  end
end
