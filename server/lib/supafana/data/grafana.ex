defmodule Supafana.Data.Grafana do
  use Supafana.Data
  alias Data.Org

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "grafana" do
    field(:supabase_id, :string)

    belongs_to(:org, Org, type: Ecto.UUID)

    field(:plan, :string, default: "Trial")
    field(:state, :string, default: "Initial")
    field(:password, :string)
    field(:first_start_at, :utc_datetime_usec)

    timestamps()
  end

  def changeset(grafana, params \\ %{}) do
    grafana
    |> cast(params, [:id, :supabase_id, :org_id, :plan, :state, :password, :first_start_at])
    |> validate_required([:supabase_id, :org_id])
  end
end
