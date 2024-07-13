defmodule Supafana.Repo.Migrations.AddOrganizationStripeCustomerTable do
  use Ecto.Migration

  def change do
    create table(:org_stripe_customer, primary_key: false) do
      add(:org_id, :uuid, null: false)
      add(:stripe_customer_id, :text, null: false)

      timestamps()
    end

    create(
      unique_index(:org_stripe_customer, [
        :org_id,
        :stripe_customer_id
      ])
    )
  end
end
