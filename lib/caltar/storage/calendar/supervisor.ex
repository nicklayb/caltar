defmodule Caltar.Storage.Calendar.Supervisor do
  use Supervisor

  alias Caltar.Storage.Calendar

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  def init(args) do
    calendar = Keyword.fetch!(args, :calendar)

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
