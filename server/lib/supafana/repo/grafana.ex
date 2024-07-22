defmodule Supafana.Repo.Grafana do
  alias Supafana.{Data, Repo}

  def set_grafana_state(project_ref, org_id, state) do
    Data.Grafana.new(%{
      supabase_id: project_ref,
      org_id: org_id,
      state: state
    })
    |> Repo.insert!(
      on_conflict: {:replace, [:state]},
      conflict_target: [:supabase_id]
    )
  end
end
