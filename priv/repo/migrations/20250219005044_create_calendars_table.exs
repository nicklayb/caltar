defmodule Caltar.Repo.Migrations.CreateCalendarsTable do
  use Ecto.Migration

  def change do
    create(table(:calendars)) do
      add(:name, :string)
      add(:slug, :string)

      timestamps()
    end

    create(unique_index(:calendars, [:slug]))
  end
end
