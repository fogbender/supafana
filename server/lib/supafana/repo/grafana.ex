defmodule Supafana.Repo.Grafana do
  alias Supafana.{Data, Repo}

  def set_state(project_ref, org_id, state) do
    Data.Grafana.new(%{
      supabase_id: project_ref,
      org_id: org_id,
      state: state
    })
    |> Repo.insert!(
      on_conflict: {:replace, [:state, :updated_at]},
      conflict_target: [:supabase_id]
    )
  end

  def set_password(project_ref, org_id, password) do
    Data.Grafana.new(%{
      supabase_id: project_ref,
      org_id: org_id,
      password: password
    })
    |> Repo.insert!(
      on_conflict: {:replace, [:password]},
      conflict_target: [:supabase_id]
    )
  end
end
