defmodule Supafana.Repo.Grafana do
  import Ecto.Query

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

    g =
      %Data.Grafana{state: new_state, first_start_at: first_start_at} =
      from(
        g in Data.Grafana,
        where: g.org_id == ^org_id,
        where: g.supabase_id == ^project_ref
      )
      |> Repo.one()

    case {new_state, first_start_at} do
      {"Running", nil} ->
        Data.Grafana
        |> Repo.get_by(supabase_id: project_ref, org_id: org_id)
        |> Data.Grafana.update(first_start_at: DateTime.utc_now())
        |> Repo.update!()

      _ ->
        g
    end
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
