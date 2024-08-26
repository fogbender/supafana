defmodule Supafana.Data.OrgStripeCustomer do
  use Supafana.Data

  @primary_key false
  schema "org_stripe_customer" do
    field(:org_id, Ecto.UUID)
    field(:stripe_customer_id, :string)
    field(:is_default, :boolean)

    has_many(:subscriptions, Supafana.Data.OrgStripeSubscription,
      references: :stripe_customer_id,
      foreign_key: :stripe_customer_id
    )

    timestamps()
  end

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, [:org_id, :stripe_customer_id, :is_default])
    |> validate_required([:org_id, :stripe_customer_id, :is_default])
    |> unique_constraint([:org_id, :is_default], name: :unique_is_default_per_org)
  end
end
