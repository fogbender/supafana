defmodule Supafana.CheckVmsJob do
  import Ecto.Query

  alias Supafana.{Azure, Data, Repo}

  @unstable_states ["Provisioning", "Deleting", "Starting", "Creating", "Unknown"]

  def run(ts \\ nil) do
    _ts = ts || DateTime.utc_now()

    update_states()
    check_trials()

    :ok
  end

  defp check_trials() do
    # XXX needs to be parameterized
    trial_number = Supafana.env(:trial_length_min)
    # XXX needs to be parameterized
    trial_unit = "minute"

    from(
      g in Data.Grafana,
      where: g.state == "Running",
      where: g.plan == "Trial",
      where: g.first_start_at < ago(^trial_number, ^trial_unit)
    )
    |> Repo.all()
    |> Enum.each(fn %{supabase_id: project_ref, org_id: org_id, first_start_at: first_start_at} ->
      IO.inspect("Deleting #{org_id} #{project_ref} #{first_start_at}")

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
      where: g.state in @unstable_states
    )
    |> Repo.all()
    |> Enum.each(fn %{supabase_id: project_ref, state: state, org_id: org_id} ->
      next_state =
        case Azure.Api.check_deployment(project_ref) do
          {:ok, %{status: 404}} ->
            "Deleted"

          {:ok, %{"properties" => %{"provisioningState" => "Failed"}}} ->
            "Failed"

          {:ok, %{"properties" => %{"provisioningState" => provisioning_state}}} ->
            IO.inspect({:provisioning_state, provisioning_state})

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

              x ->
                IO.inspect({:x, x})
                "Unknown"
            end
        end

      IO.inspect({:next_state, next_state})

      %Data.Grafana{} = Repo.Grafana.set_state(project_ref, org_id, next_state)
    end)
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
    IO.inspect({:s, s})
    parse_statuses(t)
  end

  def probe_grafana(project_ref) do
    url = "https://#{Supafana.env(:supafana_domain)}/dashboard/#{project_ref}/"

    Tesla.get(url)
  end
end
