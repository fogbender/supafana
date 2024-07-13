defmodule Supafana.Repo.Migrations.AddOrgTable do
  use Ecto.Migration

  def change do
    create table(:org, primary_key: false) do
      add(:id, :uuid, primary_key: true, null: false)
      add(:supabase_id, :string, null: false)
      add(:free_instances, :integer, default: 0)
      add(:name, :text)

      timestamps()
    end

    create(unique_index(:org, [:supabase_id]))
  end
end
