defmodule Supafana.Web.BillingRouter do
  import Ecto.Query, only: [from: 2]

  import Supafana.Web.Utils

  alias Supafana.{Data, Repo}

  use Plug.Router

  plug(:match)

  plug(:fetch_query_params)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug(Supafana.Plug.Session)

  plug(:dispatch)

  put "/subscriptions/:project_ref" do
    access_token = conn.assigns[:supabase_access_token]
    org_id = conn.assigns[:org_id]

    case ensure_own_project(access_token, project_ref) do
      false ->
        forbid(conn, "Project #{project_ref} does not belong to your Supabase organization")

      {:ok, _} ->
        subscritpions =
          from(
            s in Data.OrgStripeSubscription,
            where: s.org_id == ^org_id
          )
          |> Repo.all()

        case subscritpions do
          [] ->
            %{"url" => url} =
              Supafana.Stripe.Api.create_checkout_session(1, %{"project_ref" => project_ref})

            ok_json(
              conn,
              %{status: "redirect", url: url}
            )

          [%Data.OrgStripeSubscription{stripe_subscription_id: stripe_subscription_id} | _] ->
            %Data.Grafana{} =
              Repo.Grafana.set_stripe_subscription_id(project_ref, org_id, stripe_subscription_id)

            ok_json(conn, %{status: "success"})
        end
    end
  end

  delete "/customers/:customer_id" do
    org_id = conn.assigns[:org_id]

    c =
      from(
        c in Data.OrgStripeCustomer,
        where: c.org_id == ^org_id,
        where: c.stripe_customer_id == ^customer_id
      )
      |> Repo.one()

    case c do
      nil ->
        forbid(conn, "No such customer")

      _ ->
        :ok = Supafana.Stripe.Api.delete_customer(customer_id)

        ok_no_content(conn)
    end
  end

  post "/create-checkout-session" do
    instances = conn.params["instances"]
    %{"url" => url} = Supafana.Stripe.Api.create_checkout_session(instances)

    ok_json(
      conn,
      %{url: url}
    )
  end

  post "/create-portal-session" do
    case conn.params["stripe_subscription_id"] do
      nil ->
        send_resp(conn, 400, "stripe_subscription_id missing")

      stripe_subscription_id ->
        %Data.OrgStripeSubscription{stripe_customer_id: stripe_customer_id} =
          from(
            s in Data.OrgStripeSubscription,
            where: s.stripe_subscription_id == ^stripe_subscription_id
          )
          |> Repo.one()

        %{"url" => url} = Supafana.Stripe.Api.create_portal_session(stripe_customer_id)

        ok_json(
          conn,
          %{url: url}
        )
    end
  end

  post "/set-stripe-session-id" do
    org_id = conn.assigns[:org_id]

    if is_stripe_configured() do
      session_id = conn.params["session_id"]
      {:ok, session} = Supafana.Stripe.Api.get_checkout_session(session_id)

      %{
        "status" => "complete",
        "customer" => stripe_customer_id,
        "subscription" => stripe_subscription_id,
        "metadata" => metadata
      } = session

      case Repo.OrgStripeCustomer.add(%{
             org_id: org_id,
             stripe_customer_id: stripe_customer_id
           }) do
        {:error, :rollback} ->
          forbid(conn, "Billing profile already exists")

        {:ok, _} ->
          Data.OrgStripeSubscription.new(%{
            org_id: org_id,
            stripe_customer_id: stripe_customer_id,
            stripe_subscription_id: stripe_subscription_id
          })
          |> Repo.insert!(on_conflict: :nothing)

          {:ok, %{"created" => created_ts_sec, "email" => email}} =
            Supafana.Stripe.Api.get_customer(stripe_customer_id)

          %{"url" => portal_session_url} =
            Supafana.Stripe.Api.create_portal_session(stripe_customer_id)

          case metadata do
            %{"project_ref" => project_ref} ->
              %Data.Grafana{} =
                Repo.Grafana.set_stripe_subscription_id(
                  project_ref,
                  org_id,
                  stripe_subscription_id
                )

            _ ->
              :ok
          end

          ok_json(
            conn,
            %{
              email: email,
              created_ts_sec: created_ts_sec,
              portal_session_url: portal_session_url
            }
          )
      end
    else
      forbid(conn, "Stripe not configured")
    end
  end

  get "/billing" do
    {:ok, conn, billing} = billing(conn)

    Process.sleep(2000)

    conn |> ok_json(billing, :no_encode)
  end

  defp is_stripe_configured() do
    nil in [
      Supafana.env(:stripe_public_key),
      Supafana.env(:stripe_secret_key),
      Supafana.env(:stripe_price_id)
    ] === false
  end

  defp billing(conn) do
    org_id = conn.assigns[:org_id]

    payment_profiles =
      from(
        c in Data.OrgStripeCustomer,
        where: c.org_id == ^org_id,
        preload: [:subscriptions]
      )
      |> Repo.all()
      |> Enum.map(fn %{
                       stripe_customer_id: stripe_customer_id,
                       is_default: is_default
                     } ->
        case Supafana.Stripe.Api.get_customer(stripe_customer_id) do
          {:ok,
           %{
             "created" => created_ts_sec,
             "email" => email,
             "name" => name
           }} ->
            {:ok, %{"data" => subscriptions}} =
              Supafana.Stripe.Api.get_subscriptions(stripe_customer_id)

            subscriptions =
              subscriptions
              |> Enum.map(fn %{
                               "id" => subscription_id,
                               "current_period_end" => period_end_ts_sec,
                               "cancel_at" => cancel_at_ts_sec,
                               "canceled_at" => canceled_at_ts_sec,
                               "status" => status,
                               "quantity" => quantity,
                               "plan" => %{
                                 "product" => %{
                                   "name" => product_name
                                 }
                               }
                             } ->
                %Supafana.Z.Subscription{
                  id: subscription_id,
                  created_ts_sec: created_ts_sec,
                  period_end_ts_sec: period_end_ts_sec,
                  cancel_at_ts_sec: cancel_at_ts_sec,
                  canceled_at_ts_sec: canceled_at_ts_sec,
                  status: status,
                  quantity: quantity,
                  product_name: product_name
                }
              end)

            %Supafana.Z.PaymentProfile{
              id: stripe_customer_id,
              email: email,
              name: name,
              created_ts_sec: created_ts_sec,
              is_default: is_default,
              subscriptions: subscriptions
            }
        end
      end)
      |> Enum.filter(&(not is_nil(&1)))

    subscriptions = payment_profiles |> Enum.flat_map(& &1.subscriptions)

    # NOTE: this does not account for different products - will be wrong once that happens
    paid_instances = subscriptions |> Enum.map(& &1.quantity) |> Enum.sum()

    free_instances =
      from(
        o in Data.Org,
        where: o.id == ^org_id,
        select: o.free_instances
      )
      |> Repo.one()

    used_instances = count_used_instances(org_id)

    unpaid_instances =
      case used_instances - paid_instances - free_instances do
        instances when instances >= 0 ->
          instances

        _ ->
          0
      end

    delinquent_instances =
      subscriptions
      |> Enum.filter(&(&1.status in ["past_due", "incomplete", "incomplete_expired", "unpaid"]))
      |> Enum.map(& &1.quantity)
      |> Enum.sum()

    minimum_paid_instances = used_instances - free_instances
    active_paid_instances = paid_instances - delinquent_instances
    delinquent = active_paid_instances < minimum_paid_instances

    {:ok, %{"unit_amount" => price_per_instance}} = Supafana.Stripe.Api.get_price()

    billing =
      %Supafana.Z.Billing{
        delinquent: delinquent,
        unpaid_instances: unpaid_instances,
        paid_instances: paid_instances,
        free_instances: free_instances,
        used_instances: used_instances,
        price_per_instance: price_per_instance,
        payment_profiles: payment_profiles
      }
      |> Supafana.Z.Billing.to_json!()

    {:ok, conn, billing}
  end

  defp count_used_instances(_org_id) do
    0
  end
end
