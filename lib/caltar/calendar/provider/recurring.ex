defmodule Caltar.Calendar.Provider.Recurring do
  alias Caltar.Storage.Configuration.Recurring
  @behaviour Caltar.Calendar.Provider

  @impl Caltar.Calendar.Provider
  def poll(%DateTime{} = date_time, _old_state, %Recurring{} = recurring) do
    limit_date = DateTime.shift(date_time, month: 1)

    events = Recurring.generate(recurring, limit_date)
    {:ok, events}
  end

  @impl Caltar.Calendar.Provider
  def update(state, state, _options), do: :nothing

  def update(_old_state, events, _options) do
    {:update, events, events}
  end
end
