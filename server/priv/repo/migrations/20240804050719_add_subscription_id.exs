defmodule Supafana.Repo.Migrations.Subscriptions do
  use Ecto.Migration

  def change do
    alter table(:grafana) do
      add(:stripe_subscription_id, :text, null: true)
    end

    alter table(:org_stripe_customer) do
      add(:is_default, :boolean, null: false, default: false)
    end

    create table(:org_stripe_subscription, primary_key: false) do
      add(:org_id, :uuid, null: false)
      add(:stripe_customer_id, :text, null: false)
      add(:stripe_subscription_id, :text, null: false)

      timestamps()
    end

    create(
      unique_index(:org_stripe_customer, [:org_id],
        where: "is_default = true",
        name: :unique_is_default_per_org
      )
    )
  end
end
