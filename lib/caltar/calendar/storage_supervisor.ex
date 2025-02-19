defmodule Caltar.Calendar.StorageSupervisor do
  use Supervisor

  alias Caltar.Storage

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: Keyword.get(args, :name, __MODULE__))
  end

  def init(_args) do
    children = load_children()
    Supervisor.init(children, strategy: :one_for_one)
  end

  defp load_children do
    Storage.Calendar
    |> Caltar.Repo.all()
    |> Caltar.Repo.preload([:providers])
    |> Enum.map(&build_child/1)
  end

  defp build_child(%Storage.Calendar{slug: slug, providers: providers}) do
    {Caltar.Storage.Calendar.Supervisor, slug: slug, providers: providers}
  end

  def get_supervisor(slug) do
    Caltar.Calendar.StorageSupervisor
    |> Supervisor.which_children()
    |> Enum.find_value(fn
      {{Caltar.Storage.Calendar.Supervisor, ^slug}, pid, _, _} -> pid
      _ -> false
    end)
  end

  def get_calendar_server(slug) when is_binary(slug) do
    slug
    |> get_supervisor()
    |> get_calendar_server()
  end

  def get_calendar_server(supervisor_pid) when is_pid(supervisor_pid) do
    supervisor_pid
    |> Supervisor.which_children()
    |> Enum.find_value(fn
      {_, pid, _, [Caltar.Calendar.Server]} -> pid
      _ -> nil
    end)
  end
end
