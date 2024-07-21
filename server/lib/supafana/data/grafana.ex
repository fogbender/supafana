defmodule Supafana.Data.Grafana do
  use Supafana.Data
  alias Supafana.{Org}

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "grafana" do
    field(:supabase_id, :string)

    belongs_to(:org, Org, type: Ecto.UUID)

    field(:plan, :string, default: "free")
    field(:state, :string, default: "initial")

    timestamps()
  end

  def changeset(grafana, params \\ %{}) do
    grafana
    |> cast(params, [:id, :supabase_id, :org_id, :plan, :state])
    |> validate_required([:supabase_id, :org_id])
  end
end
