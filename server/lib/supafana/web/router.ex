defmodule Supafana.Web.Router do
  require Logger

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

  get "/organizations" do
    access_token = conn.assigns[:supabase_access_token]

    {:ok, organizations} = Supafana.Supabase.Management.organizations(access_token)

    conn |> ok_json(organizations)
  end

  get "/projects" do
    access_token = conn.assigns[:supabase_access_token]

    {:ok, projects} = Supafana.Supabase.Management.projects(access_token)

    conn |> ok_json(projects)
  end

  defp ok_json(conn, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, data |> Jason.encode!(pretty: true))
  end
end
