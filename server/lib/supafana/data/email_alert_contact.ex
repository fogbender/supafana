defmodule Supafana.Data.EmailAlertContact do
  use Supafana.Data
  alias Data.Grafana

  @primary_key false
  schema "email_alert_contact" do
    belongs_to(:grafana, Grafana, type: Ecto.UUID)

    field(:supabase_id, :string)
    field(:email, :string)
    field(:severity, :string)

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :grafana_id,
      :supabase_id,
      :email,
      :severity
    ])
    |> validate_required([:grafana_id, :supabase_id, :email, :severity])
    |> unique_constraint([:grafana_id, :email], name: :unique_email_alert_contact_per_grafana)
  end
end
