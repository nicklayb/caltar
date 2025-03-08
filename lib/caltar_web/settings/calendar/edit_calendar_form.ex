defmodule CaltarWeb.Settings.Calendar.EditCalendarForm do
  use Ecto.Schema

  alias CaltarWeb.Settings.Calendar.EditCalendarForm

  embedded_schema do
    field(:base_type, :string)
    field(:weeks_before, :integer)
    field(:weeks_after, :integer)
  end

  @base_types ~w(current_month relative)

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

  def apply(%Ecto.Changeset{} = changeset) do
    with {:ok, %EditCalendarForm{} = form} <- Ecto.Changeset.apply_action(changeset, :insert) do
      apply(form)
    end
  end

  def apply(%EditCalendarForm{base_type: "current_month"}), do: :current_month

  def apply(%EditCalendarForm{
        base_type: "relative",
        weeks_before: weeks_before,
        weeks_after: weeks_after
      }),
      do: {:relative, weeks_before, weeks_after}
end
