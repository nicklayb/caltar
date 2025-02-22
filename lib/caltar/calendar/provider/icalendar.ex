defmodule Caltar.Calendar.Provider.Icalendar do
  @behaviour Caltar.Calendar.Provider

  @impl Caltar.Calendar.Provider
  def poll(%DateTime{} = date_time, old_state, options) do
    {:ok, %{}}
  end

  @impl Caltar.Calendar.Provider
  def update(old_state, new_state, options) do
    {:update, new_state, []}
  end
end
