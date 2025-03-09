defmodule Caltar.Storage.UseCase.UpdateCalendar do
  alias Caltar.Storage.Calendar
  use Box.UseCase

  @impl Box.UseCase
  def validate(params, _) do
    with {:calendar_id, calendar_id} <- Box.Map.get_first(params, [:calendar_id]),
         true <- Caltar.Storage.calendar_exists?(calendar_id) do
      {:ok, {calendar_id, params}}
    else
      _ -> {:error, :not_found}
    end
  end

  @impl Box.UseCase
  def run(multi, {calendar_id, params}, _) do
    multi
    |> Ecto.Multi.one(:get_calendar, Calendar.Query.by_id(calendar_id))
    |> Ecto.Multi.update(
      :calendar,
      fn %{get_calendar: %Calendar{} = calendar} ->
        Calendar.changeset(calendar, params)
      end
    )
  end

  @impl Box.UseCase
  def after_run(%{calendar: %Calendar{} = calendar}, _) do
    Caltar.PubSub.broadcast("calendars", {:updated, calendar})
  end

  @impl Box.UseCase
  def return(%{calendar: calendar}, _) do
    calendar
  end
end
