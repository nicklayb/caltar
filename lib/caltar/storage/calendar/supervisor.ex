defmodule Caltar.Storage.Calendar.Supervisor do
  use Supervisor

  alias Caltar.Calendar.StorageSupervisor
  alias Caltar.Storage.Calendar
  alias Caltar.Repo

  @namespace Caltar.Storage.Calendar.Supervisor

  def start_link(args) do
    %Calendar{id: id, slug: slug} = Keyword.fetch!(args, :calendar)

    Supervisor.start_link(__MODULE__, args,
      name: StorageSupervisor.registry_name({@namespace, id, slug})
    )
  end

  def init(args) do
    calendar =
      args
      |> Keyword.fetch!(:calendar)
      |> then(&Repo.get(Calendar, &1.id))

    Supervisor.init(
      [
        {Caltar.Calendar.Server, calendar: calendar},
        {DynamicSupervisor, strategy: :one_for_one},
        {Caltar.Calendar.Controller, slug: calendar.slug, supervisor_pid: self()}
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
