defmodule Supafana.Data.OrgStripeCustomer do
  use Supafana.Data

  @primary_key false
  schema "org_stripe_customer" do
    field(:org_id, Ecto.UUID)
    field(:stripe_customer_id, :string)

    timestamps()
  end

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, [:org_id, :stripe_customer_id])
    |> validate_required([:org_id, :stripe_customer_id])
  end
end
