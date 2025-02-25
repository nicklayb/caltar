defmodule Caltar.Storage.Calendar.Supervisor do
  use Supervisor

  alias Caltar.Calendar.Poller
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
      Enum.map(providers, &poller_child_spec(&1, supervisor_pid: self()))

    Supervisor.init(
      [
        {Caltar.Calendar.Server, slug: slug},
        {Caltar.Calendar.Controller, slug: slug, supervisor_pid: self()}
        | children
      ],
      strategy: :one_for_one
    )
  end

  defp poller_child_spec(
         %Provider{
           id: id,
           configuration: %configuration_struct{} = configuration,
           every: every,
           color: color
         },
         options
       ) do
    supervisor_pid = Keyword.fetch!(options, :supervisor_pid)

    %{
      id: {__MODULE__, id},
      start:
        {Poller, :start_link,
         [
           [
             id: id,
             provider: configuration_struct.poller_spec(configuration),
             color: color,
             supervisor_pid: supervisor_pid,
             every: every || :never
           ]
         ]}
    }
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
