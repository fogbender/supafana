defmodule Supafana.Repo.Migrations.AddEmailAlertContactTable do
  use Ecto.Migration

  def change do
    create table(:email_alert_contact, primary_key: false) do
      add(:grafana_id, :uuid, null: false)
      add(:supabase_id, :text, null: false)
      add(:email, :text, null: false)
      add(:severity, :text, null: false, default: "critical")

      timestamps()
    end

    create(
      unique_index(
        :email_alert_contact,
        [:grafana_id, :email],
        title: :unique_email_alert_contact_per_grafana
      )
    )

    create table(:alert, primary_key: false) do
      add(:grafana_id, :uuid, null: false)
      add(:supabase_id, :text, null: false)
      add(:enabled, :boolean, null: false, default: true)
      add(:title, :text, null: false)

      timestamps()
    end

    create(
      unique_index(
        :alert,
        [:grafana_id, :title],
        title: :unique_alert_per_grafana
      )
    )

    alter table(:grafana) do
      add(:max_client_connections, :integer, default: 200)
    end
  end
end
