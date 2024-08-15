defmodule Supafana.Repo.Migrations.AddUserNotificationTable do
  use Ecto.Migration

  def change do
    create table(:user_notification, primary_key: false) do
      add(:org_id, :uuid, null: false)
      add(:user_id, :text, null: false)
      add(:email, :text, null: false)

      add(:tx_emails, :boolean, null: false, default: false)

      timestamps()
    end

    create(
      unique_index(
        :user_notification,
        [:org_id, :user_id],
        name: :unique_user_per_org
      )
    )
  end
end
