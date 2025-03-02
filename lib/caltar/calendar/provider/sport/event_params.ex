defmodule Caltar.Calendar.Provider.Sport.EventParams do
  defstruct [:id, :sport, :team_id, :game_date, :progress, :home, :away]

  defmodule Progress do
    defstruct [:status, :clock, :clock_status]
  end

  defmodule Side do
    defstruct [:avatar, :name, :score]
  end
end
