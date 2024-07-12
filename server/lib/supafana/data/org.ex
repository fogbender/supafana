defmodule Supafana.Data.Org do
  use Supafana.Data

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "org" do
    field(:supabase_id, :string)
    field(:name, :string)
    timestamps()
  end

  def changeset(org, params \\ %{}) do
    org
    |> cast(params, [:id, :supabase_id, :name])
    |> validate_required([:supabase_id])
  end
end
