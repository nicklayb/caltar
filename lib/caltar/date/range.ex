defmodule Caltar.Date.Range do
  defstruct [:start_date, :end_date, :current_date]

  alias Caltar.Date.Range, as: DateRange

  def new(current_date, start_date, end_date) do
    %DateRange{
      current_date: current_date,
      start_date: start_date,
      end_date: end_date
    }
  end
end
