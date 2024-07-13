defmodule Supafana.Web.AuthUtils do
  import Ecto.Query, only: [from: 2]

  import Supafana.Web.Utils

  alias Supafana.{Data, Repo}

  def handle_auth(conn, code, redirect_uri, code_verifier) do
    {:ok, tokens} = Supafana.Supabase.OAuth.tokens(code, redirect_uri, code_verifier)
    handle_tokens(conn, tokens)
  end

  def handle_auth(conn, supabase_refresh_token) do
    # TODO: use existing token if not expired

    # {:ok, tokens} = Supafana.Supabase.OAuth.token(supabase_refresh_token)

    supabase_access_token = Plug.Conn.get_session(conn, :supabase_access_token)

    handle_tokens(conn, %{
      "access_token" => supabase_access_token,
      "refresh_token" => supabase_refresh_token
    })
  end

  defp handle_tokens(conn, %{status: 404}) do
    conn |> not_authorized()
  end

  defp handle_tokens(conn, tokens) do
    %{
      "access_token" => access_token,
      "refresh_token" => refresh_token
    } = tokens

    conn = Plug.Conn.put_session(conn, :supabase_access_token, access_token)
    conn = Plug.Conn.put_session(conn, :supabase_refresh_token, refresh_token)

    {:ok, orgs} = Supafana.Supabase.Management.organizations(access_token)

    [org] = orgs
    supabase_org_id = org["id"]

    Data.Org.new(%{
      supabase_id: supabase_org_id
    })
    |> Repo.insert!(on_conflict: :nothing)

    %Data.Org{id: org_id} =
      from(
        o in Data.Org,
        where: o.supabase_id == ^supabase_org_id
      )
      |> Repo.one()

    conn = Plug.Conn.assign(conn, :supabase_access_token, access_token)
    Plug.Conn.assign(conn, :org_id, org_id)
  end
end
