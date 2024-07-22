defmodule Supafana.CheckVmsJob do
  import Ecto.Query, only: [from: 2]

  alias Supafana.{Azure, Data, Repo}

  @unstable_states ["Initializing", "Deleting"]

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
          case Azure.Api.check_vm(project_ref) do
            {:error, :not_found} ->
              case state do
                "Initial" ->
                  "Initial"

                "Deleting" ->
                  "Deleted"
              end

            {:ok, %{"statuses" => statuses}} ->
              case statuses |> Enum.find(&(&1["code"] == "ProvisioningState/succeeded")) do
                nil ->
                  "Unknown"

                %{"code" => "ProvisioningState/succeeded"} ->
                  "Running"
              end

            _ ->
              "Unknown"
          end

        %Data.Grafana{} = Repo.Grafana.set_grafana_state(project_ref, org_id, next_state)
      end)

    :ok
  end
end
