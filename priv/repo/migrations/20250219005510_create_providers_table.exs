defmodule Caltar.Repo.Migrations.CreateProvidersTable do
  use Ecto.Migration

  def change do
    create(table(:providers)) do
      add(:calendar_id, references(:calendar, on_delete: :delete_all), null: false)
      add(:configuration, :map, null: false)
    end
  end
end
