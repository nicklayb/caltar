defmodule Caltar.Storage.Configuration do
  alias Caltar.Storage.Provider

  @callback poller_spec(Provider.t()) :: {:poller, module()} | Supervisor.child_spec()
  @callback poll_every_timer(struct()) :: non_neg_integer() | :never
end
