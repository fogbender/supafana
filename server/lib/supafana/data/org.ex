defmodule Supafana.Data.Org do
  use Supafana.Data

  alias Supafana.Data.{Grafana, OrgStripeCustomer}

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "org" do
    field(:supabase_id, :string)
    field(:name, :string)
    field(:free_instances, :integer, default: 0)

    has_many(:grafanas, Grafana)
    has_many(:org_stripe_customers, OrgStripeCustomer)

    timestamps()
  end

  def changeset(org, params \\ %{}) do
    org
    |> cast(params, [:id, :supabase_id, :name])
    |> validate_required([:supabase_id])
  end
end
