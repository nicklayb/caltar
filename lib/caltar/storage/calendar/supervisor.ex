defmodule Caltar.Storage.Calendar.Supervisor do
  use Supervisor

  alias Caltar.Storage.Provider

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  def init(args) do
    providers = Keyword.fetch!(args, :providers)

    children =
      Enum.map(providers, fn %Provider{configuration: %struct{}} = provider ->
        {struct, provider: provider, supervisor_pid: self()}
      end)

    Supervisor.init(
      [
        Caltar.Calendar.Server
        | children
      ],
      strategy: :one_for_one
    )
  end

  def child_spec(args) do
    slug = Keyword.fetch!(args, :slug)

    default = %{
      id: {__MODULE__, slug},
      start: {__MODULE__, :start_link, [args]},
      type: :supervisor
    }

    Supervisor.child_spec(default, [])
  end
end
