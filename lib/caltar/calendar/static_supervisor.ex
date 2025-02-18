defmodule Caltar.Calendar.StaticSupervisor do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: Keyword.fetch!(args, :name))
  end

  def init(args) do
    name = Keyword.fetch!(args, :name)

    providers =
      args
      |> Keyword.get(:providers, [])
      |> Enum.map(&{CalendarPoller, provider: &1, supervisor_name: name})

    children = []

    Supervisor.init(children, strategy: :one_for_one)
  end
end
