defmodule KoombeaScraper.Repo.Migrations.CreateLinks do
  use Ecto.Migration

  def change do
    create table(:links) do
      add :name, :text
      add :url, :string
      add :page_id, references(:pages, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:links, [:page_id])
  end
end
