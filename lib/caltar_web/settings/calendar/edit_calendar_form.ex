defmodule CaltarWeb.Settings.Calendar.EditCalendarForm do
  use Ecto.Schema

  alias Caltar.Storage.Calendar
  alias CaltarWeb.Settings.Calendar.EditCalendarForm

  embedded_schema do
    field(:base_type, :string)
    field(:weeks_before, :integer)
    field(:weeks_after, :integer)
  end

  @base_types ~w(current_month relative)
  def base_types, do: @base_types

  @required ~w(base_type)a
  @optional ~w(weeks_before weeks_after)a
  @castable @required ++ @optional
  def changeset(%EditCalendarForm{} = form \\ %EditCalendarForm{}, params) do
    form
    |> Ecto.Changeset.cast(params, @castable)
    |> Ecto.Changeset.validate_required(@required)
    |> Ecto.Changeset.validate_inclusion(:base_type, @base_types)
    |> Box.Ecto.Changeset.update_valid(&validate_type_arguments/1)
  end

  @relative_required ~w(weeks_before weeks_after)a
  defp validate_type_arguments(%Ecto.Changeset{changes: %{base_type: "relative"}} = changeset) do
    changeset
    |> Ecto.Changeset.validate_required(@relative_required)
    |> Ecto.Changeset.validate_number(:weeks_before, greater_than_or_equal_to: 0)
    |> Ecto.Changeset.validate_number(:weeks_after, greater_than_or_equal_to: 0)
  end

  defp validate_type_arguments(%Ecto.Changeset{} = changeset) do
    changeset
  end

  def cast_display_mode(%EditCalendarForm{base_type: "current_month"}), do: :current_month

  def cast_display_mode(%EditCalendarForm{
        base_type: "relative",
        weeks_before: weeks_before,
        weeks_after: weeks_after
      }),
      do: {:relative, weeks_before, weeks_after}

  def to_changeset_params(%EditCalendarForm{} = form, %Calendar{id: calendar_id}) do
    display_mode = cast_display_mode(form)

    %{
      calendar_id: calendar_id,
      display_mode: display_mode
    }
  end

  def from_calendar(%Calendar{display_mode: :current_month}) do
    %EditCalendarForm{base_type: "current_month"}
  end

  def from_calendar(%Calendar{display_mode: {:relative, weeks}}) do
    %EditCalendarForm{base_type: "relative", weeks_before: weeks, weeks_after: weeks}
  end

  def from_calendar(%Calendar{display_mode: {:relative, weeks_before, weeks_after}}) do
    %EditCalendarForm{base_type: "relative", weeks_before: weeks_before, weeks_after: weeks_after}
  end
end
