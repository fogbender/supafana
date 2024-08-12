defmodule Supafana.Data.OrgStripeSubscription do
  use Supafana.Data

  @primary_key false
  schema "org_stripe_subscription" do
    field(:org_id, Ecto.UUID)
    field(:stripe_customer_id, :string)
    field(:stripe_subscription_id, :string)

    timestamps()
  end

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, [:org_id, :stripe_customer_id, :stripe_subscription_id])
    |> validate_required([:org_id, :stripe_customer_id, :stripe_subscription_id])
  end
end
