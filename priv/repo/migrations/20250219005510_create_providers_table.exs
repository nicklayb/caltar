defmodule Caltar.Repo.Migrations.CreateProvidersTable do
  use Ecto.Migration

  def change do
    create(table(:providers)) do
      add(:name, :string, null: false)
      add(:calendar_id, references(:calendars, on_delete: :delete_all), null: false)
      add(:configuration, :map, null: false)
      add(:color, :map, null: false)
      add(:every, :integer, null: true)

      timestamps()
    end

    create(index(:providers, [:calendar_id]))
    create(unique_index(:providers, [:calendar_id, :name]))
  end
end
