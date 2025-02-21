defmodule Caltar.Storage.Calendar.Supervisor do
  use Supervisor

  alias Caltar.Storage.Calendar
  alias Caltar.Repo
  alias Caltar.Storage.Provider

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  def init(args) do
    %Calendar{slug: slug, providers: providers} =
      args
      |> Keyword.fetch!(:calendar)
      |> Repo.preload([:providers])

    children =
      Enum.map(providers, fn %Provider{configuration: %struct{}} = provider ->
        {struct, provider: provider, supervisor_pid: self()}
      end)

    Supervisor.init(
      [
        Caltar.Calendar.Server,
        {Caltar.Calendar.Controller, slug: slug, supervisor_pid: self()}
        | children
      ],
      strategy: :one_for_one
    )
  end

  def child_spec(args) do
    %Calendar{slug: slug} = Keyword.fetch!(args, :calendar)

    default = %{
      id: {__MODULE__, slug},
      start: {__MODULE__, :start_link, [args]},
      type: :supervisor
    }

    Supervisor.child_spec(default, [])
  end
end
