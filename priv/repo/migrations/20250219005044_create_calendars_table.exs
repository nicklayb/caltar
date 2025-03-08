defmodule Caltar.Repo.Migrations.CreateCalendarsTable do
  use Ecto.Migration

  def change do
    create(table(:calendars)) do
      add(:name, :string, null: false)
      add(:slug, :string, null: false)

      add(:display_mode, :string, null: false)

      timestamps()
    end

    create(unique_index(:calendars, [:slug]))
  end
end
