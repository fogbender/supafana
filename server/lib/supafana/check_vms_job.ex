defmodule Supafana.CheckVmsJob do
  import Ecto.Query, only: [from: 2]

  alias Supafana.{Azure, Data, Repo}

  @unstable_states ["Provisioning", "Deleting", "Starting", "Creating", "Unknown"]

  def run(ts \\ nil) do
    _ts = ts || DateTime.utc_now()

    _unstable_grafanas =
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

                    "Provisioning" ->
                      "Provisioning"

                    "Deleting" ->
                      "Deleted"
                  end

                {:ok, %{"statuses" => statuses}} ->
                  parse_statuses(statuses)

                x ->
                  IO.inspect({:x, x})
                  "Unknown"
              end
          end

        IO.inspect({:next_state, next_state})

        %Data.Grafana{} = Repo.Grafana.set_state(project_ref, org_id, next_state)
      end)

    :ok
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
end
