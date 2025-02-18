defmodule Caltar.Calendar.Provider do
  alias Caltar.Calendar.Event

  @type state :: any()
  @type options :: Keyword.t()

  @callback poll(DateTime.t(), state(), options()) ::
              {:ok, state()} | {:error, any()}

  @callback update(state(), state(), options()) ::
              {:update, state(), [Event.t()]} | {:update, state()} | :nothing
end
