defmodule Caltar.Calendar.Provider.Recurring do
  @behaviour Caltar.Calendar.Provider

  alias Caltar.Storage.Provider
  alias Caltar.Storage.Configuration.Recurring

  @impl Caltar.Calendar.Provider
  def poll(%DateTime{} = date_time, _old_state, %Provider{configuration: %Recurring{} = recurring}) do
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
