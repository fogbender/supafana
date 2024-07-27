defmodule Supafana.Repo.Migrations.AddGrafanaInitialRunColumn do
  use Ecto.Migration

  def change do
    alter table(:grafana) do
      add(:first_start_at, :utc_datetime_usec, null: true)
    end
  end
end
