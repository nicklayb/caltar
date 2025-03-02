defmodule Caltar.Calendar.Provider do
  alias Caltar.Calendar.Event
  alias Caltar.Calendar.Marker

  defmodule UpdateResult do
    defstruct reconfigure: [], events: :no_update, state: nil

    @type state :: any()
    @type every :: [{:every, non_neg_integer() | :never | nil}]
    @type events :: [Event.t() | Marker.t()] | :no_update

    @type t :: %UpdateResult{
            reconfigure: every(),
            events: events(),
            state: state()
          }
  end

  @type state :: UpdateResult.state()
  @type options :: struct()

  @type update_result :: UpdateResult.t()

  @callback poll(DateTime.t(), state(), options()) ::
              {:ok, state()} | {:error, any()}

  @callback update(state(), state(), options()) :: update_result()

  def update_state(%UpdateResult{} = result \\ %UpdateResult{}, new_state) do
    %UpdateResult{result | state: new_state}
  end

  @reconfigurable_keys ~w(every)a
  def reconfigure(%UpdateResult{reconfigure: reconfigure} = update \\ %UpdateResult{}, key, value)
      when key in @reconfigurable_keys do
    %UpdateResult{update | reconfigure: [{key, value} | reconfigure]}
  end

  def with_events(%UpdateResult{} = update \\ %UpdateResult{}, events) do
    %UpdateResult{update | events: events}
  end

  def no_events_updated(%UpdateResult{} = update \\ %UpdateResult{}) do
    with_events(update, :no_update)
  end

  defmacro __using__(_) do
    quote do
      @behaviour Caltar.Calendar.Provider
      import Caltar.Calendar.Provider
    end
  end
end
