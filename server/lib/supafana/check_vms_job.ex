defmodule Supafana.CheckVmsJob do
  require Logger

  import Ecto.Query

  alias Supafana.{Azure, Stripe, Data, Repo}

  @unstable_states ["Provisioning", "Deleting", "Starting", "Creating", "Failed", "Unknown"]

  def run(ts \\ nil) do
    _ts = ts || DateTime.utc_now()

    update_states()
    check_trials()
    check_subscriptions()

    :ok
  end

  defp check_subscriptions() do
    from(
      o in Data.Org,
      join: g in assoc(o, :grafanas),
      where: g.plan == "Supafana Pro",
      preload: [:grafanas, org_stripe_customers: [:subscriptions]],
      group_by: [o.id]
    )
    |> Repo.all()
    |> Enum.map(fn %{
                     id: org_id,
                     org_stripe_customers: stripe_customers,
                     grafanas: grafanas,
                     free_instances: free_instances
                   } ->
      case stripe_customers |> Enum.find(&(length(&1.subscriptions) > 0)) do
        nil ->
          active_grafanas =
            grafanas
            |> Enum.filter(&(&1.state == "Running" && &1.plan == "Supafana Pro"))
            |> length

          cond do
            active_grafanas > 0 ->
              Logger.error(
                "#{org_id} does not have an active subscription, but has running Grafanas"
              )

            true ->
              :ok
          end

        %Data.OrgStripeCustomer{
          stripe_customer_id: _stripe_customer_id,
          subscriptions: subscriptions
        } ->
          # For now, there can be only one subscription - until we offer other products
          [%Data.OrgStripeSubscription{stripe_subscription_id: stripe_subscription_id} | _] =
            subscriptions

          {:ok, subscription} = Stripe.Api.get_subscription(stripe_subscription_id)

          IO.inspect({:subscription, subscription})

          price_id = Supafana.env(:stripe_price_id)

          case subscription["plan"]["id"] do
            ^price_id ->
              quantity = subscription["quantity"]

              grafanas =
                grafanas |> Enum.filter(&(&1.plan == "Supafana Pro"))

              active_grafanas = grafanas |> Enum.filter(&(&1.state == "Running")) |> length

              balance = active_grafanas - (quantity + free_instances)

              cond do
                balance == 0 ->
                  :ok

                true ->
                  new_quantity = active_grafanas - free_instances

                  subscription_item =
                    subscription["items"]["data"] |> Enum.find(&(&1["plan"]["id"] == price_id))

                  case subscription_item do
                    %{"id" => subscription_item_id} ->
                      {:ok, _} =
                        Stripe.Api.set_subscription_plan_quantity(
                          subscription_item_id,
                          new_quantity
                        )
                  end
              end

              Logger.debug("#{active_grafanas} grafanas here, subscription is for #{quantity}")
          end
      end
    end)
  end

  defp check_trials() do
    trial_number = Supafana.env(:trial_length_min)
    trial_unit = "minute"

    from(
      g in Data.Grafana,
      where: g.state == "Running",
      where: g.plan == "Trial",
      where: g.first_start_at < ago(^trial_number, ^trial_unit)
    )
    |> Repo.all()
    |> Enum.each(fn %{supabase_id: project_ref, org_id: org_id, first_start_at: first_start_at} ->
      Logger.info("Deleting #{org_id} #{project_ref} #{first_start_at}")

      Supafana.Web.Task.schedule(
        operation: :delete_vm,
        project_ref: project_ref,
        org_id: org_id
      )

      :ok
    end)
  end

  defp update_states() do
    from(
      g in Data.Grafana,
      where: g.state in @unstable_states or (g.state == "Running" and g.plan == "Trial")
    )
    |> Repo.all()
    |> Enum.each(fn %{supabase_id: project_ref, state: state, org_id: org_id} ->
      next_state =
        case Azure.Api.check_deployment(project_ref) do
          {:ok, %{status: 404}} ->
            "Deleted"

          {:ok, %{"properties" => %{"provisioningState" => "Failed"}}} ->
            # "Failed"
            check_vm(project_ref, state)

          {:ok, %{"properties" => %{"provisioningState" => provisioning_state}}} ->
            Logger.info("provisioning_state for #{project_ref}: #{provisioning_state}")
            check_vm(project_ref, state)
        end

      Logger.info("next_state for #{project_ref}: #{next_state}")

      %Data.Grafana{} = Repo.Grafana.set_state(project_ref, org_id, next_state)
    end)
  end

  defp check_vm(project_ref, state) do
    case Azure.Api.check_vm(project_ref) do
      {:error, :not_found} ->
        case state do
          "Initial" ->
            "Initial"

          "Starting" ->
            "Starting"

          "Provisioning" ->
            "Provisioning"

          "Deleting" ->
            "Deleted"
        end

      {:ok, %{"statuses" => statuses}} ->
        case parse_statuses(statuses) do
          "Running" ->
            case probe_grafana(project_ref) do
              {:ok, %{status: 302}} ->
                "Running"

              _ ->
                "Starting"
            end

          state ->
            state
        end

      check_vm_result ->
        Logger.info("Unknown check_vm result: #{inspect(check_vm_result)}")
        "Unknown"
    end
  end

  defp parse_statuses([]) do
    "Unknown"
  end

  defp parse_statuses([%{"code" => "PowerState/running"} | _]) do
    "Running"
  end

  defp parse_statuses([%{"code" => "ProvisioningState/deleting"} | _]) do
    "Deleting"
  end

  defp parse_statuses([%{"code" => "ProvisioningState/creating"} | _]) do
    "Creating"
  end

  defp parse_statuses([%{"code" => "PowerState/creating"} | _]) do
    "Creating"
  end

  defp parse_statuses([%{"code" => "PowerState/starting"} | _]) do
    "Starting"
  end

  defp parse_statuses([s | t]) do
    Logger.debug("#{inspect({:s, s})}")
    parse_statuses(t)
  end

  def probe_grafana(project_ref) do
    url = "https://#{Supafana.env(:supafana_domain)}/dashboard/#{project_ref}/"

    Tesla.get(url)
  end
end
