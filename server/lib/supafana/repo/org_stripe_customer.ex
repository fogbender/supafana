defmodule Supafana.Repo.OrgStripeCustomer do
  import Ecto.Query

  alias Supafana.{Repo}
  alias Supafana.Data.{OrgStripeCustomer}

  def add(attrs) do
    res =
      Repo.transaction(fn ->
        org_id = Map.get(attrs, :org_id)
        stripe_customer_id = Map.get(attrs, :stripe_customer_id)

        has_entries =
          from(c in OrgStripeCustomer,
            where: c.org_id == ^org_id,
            where: c.stripe_customer_id == ^stripe_customer_id
          )
          |> Repo.exists?()

        attrs =
          if not has_entries do
            Map.put(attrs, :is_default, true)
          else
            attrs
          end

        changeset = OrgStripeCustomer.changeset(%OrgStripeCustomer{}, attrs)

        Repo.insert(changeset)
      end)

    case res do
      {:error, :rollback} ->
        changeset =
          OrgStripeCustomer.changeset(%OrgStripeCustomer{}, Map.put(attrs, :is_default, false))

        {:ok, Repo.insert!(changeset, on_conflict: :nothing)}

      _ ->
        res
    end
  end
end
