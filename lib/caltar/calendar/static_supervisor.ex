defmodule Caltar.Calendar.StaticSupervisor do
  alias Caltar.Calendar
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: Keyword.fetch!(args, :name))
  end

  def init(args) do
    providers =
      args
      |> Keyword.get(:providers, [])
      |> Enum.map(&add_option(&1, :supervisor_pid, self()))

    children = [
      Calendar.Server
      | providers
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  defp add_option({module, options}, key, value) do
    {module, Keyword.put(options, key, value)}
  end

  defp add_option(module, key, value) do
    add_option({module, []}, key, value)
  end
end
