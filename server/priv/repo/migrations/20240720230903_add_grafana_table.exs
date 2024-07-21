defmodule Supafana.Repo.Migrations.AddGrafanaTable do
  use Ecto.Migration

  def change do
    create table(:grafana, primary_key: false) do
      add(:id, :uuid, primary_key: true, null: false)
      add(:supabase_id, :string, null: false)
      add(:org_id, :uuid, null: false)
      add(:plan, :string, default: "free")
      add(:state, :string, default: "initial")

      timestamps()
    end

    create(unique_index(:grafana, [:supabase_id]))
  end
end
