defmodule Supafana.Data.Alert do
  use Supafana.Data
  alias Data.Grafana

  @primary_key false
  schema "alert" do
    belongs_to(:grafana, Grafana, type: Ecto.UUID)

    field(:supabase_id, :string)
    field(:title, :string)
    field(:enabled, :boolean)

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :grafana_id,
      :supabase_id,
      :title,
      :enabled
    ])
    |> validate_required([:grafana_id, :supabase_id, :title, :enabled])
    |> unique_constraint([:grafana_id, :title], name: :unique_alert_per_grafana)
  end
end
