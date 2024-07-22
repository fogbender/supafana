defmodule Supafana.Web.Task do
  require Logger

  def child_spec() do
    {Task.Supervisor, name: __MODULE__}
  end

  def schedule(params) do
    Task.Supervisor.async_nolink(Supafana.TaskSupervisor, __MODULE__, :run, [params])
  end

  def run(operation: :delete_vm, project_ref: project_ref, org_id: org_id) do
    :ok = Supafana.Azure.Api.delete_vm(project_ref)

    %Supafana.Data.Grafana{} =
      Supafana.Repo.Grafana.set_grafana_state(project_ref, org_id, "Deleted")
  end
end
