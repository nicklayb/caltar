defmodule Caltar.Boot do
  use GenServer, restart: :temporary

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, :start_link)
  end

  def init(_) do
    Logger.info("[#{inspect(__MODULE__)}] starting")
    create_main_calendar()
    :ignore
  end

  defp create_main_calendar do
    if not Caltar.Storage.calendar_slug_exists?("main") do
      %{name: "Main", display_mode: "relative:1:1"}
      |> Caltar.Storage.Calendar.changeset()
      |> Caltar.Repo.insert!()

      Logger.info("[#{inspect(__MODULE__)}] main calendar created")
    else
      Logger.info("[#{inspect(__MODULE__)}] main calendar already exists")
    end
  end
end
