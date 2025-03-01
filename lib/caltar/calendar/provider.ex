defmodule Caltar.Calendar.Provider do
  alias Caltar.Calendar.Event
  alias Caltar.Calendar.Marker

  @type state :: any()
  @type options :: struct()

  @callback poll(DateTime.t(), state(), options()) ::
              {:ok, state()} | {:error, any()}

  @callback update(state(), state(), options()) ::
              {:update, state(), [Event.t() | Marker.t()]} | {:update, state()} | :nothing
end
