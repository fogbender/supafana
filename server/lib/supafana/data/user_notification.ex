defmodule Supafana.Data.UserNotification do
  use Supafana.Data
  alias Data.Org

  @primary_key false
  schema "user_notification" do
    belongs_to(:org, Org, type: Ecto.UUID)

    field(:tx_emails, :boolean, default: false)
    field(:email, :string)
    field(:user_id, :string)

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :org_id,
      :user_id,
      :email,
      :tx_emails
    ])
    |> validate_required([:org_id, :user_id, :email, :tx_emails])
    |> unique_constraint([:org_id, :user_id], name: :unique_user_per_org)
  end
end
