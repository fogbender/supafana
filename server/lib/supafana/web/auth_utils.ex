defmodule Supafana.Web.AuthUtils do
  require Logger

  import Ecto.Query, only: [from: 2]

  import Plug.Conn

  alias Supafana.{Data, Repo}

  def handle_auth(conn, code, redirect_uri, code_verifier) do
    {:ok, tokens} = Supafana.Supabase.OAuth.tokens(code, redirect_uri, code_verifier)

    Logger.debug("tokens: #{inspect(tokens)}")

    handle_tokens(conn, tokens)
  end

  def handle_auth(conn, supabase_refresh_token) do
    # TODO: use existing token if not expired

    # {:ok, tokens} = Supafana.Supabase.OAuth.token(supabase_refresh_token)

    supabase_access_token = get_session(conn, :supabase_access_token)

    handle_tokens(conn, %{
      "access_token" => supabase_access_token,
      "refresh_token" => supabase_refresh_token
    })
  end

  defp handle_tokens(conn, %{status: 502} = res) do
    Logger.error("handle_tokens error - #{inspect(res)}")

    conn |> not_authorized_with_redirect()
  end

  defp handle_tokens(conn, %{status: 404} = res) do
    Logger.error("handle_tokens error - #{inspect(res)}")

    conn |> not_authorized_with_redirect()
  end

  defp handle_tokens(conn, tokens) do
    %{
      "access_token" => access_token,
      "refresh_token" => refresh_token
    } = tokens

    conn = put_session(conn, :supabase_access_token, access_token)
    conn = put_session(conn, :supabase_refresh_token, refresh_token)

    case Supafana.Supabase.Management.organizations(access_token) do
      {:ok, %Tesla.Env{status: 200, body: orgs}} ->
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

        conn = assign(conn, :supabase_access_token, access_token)
        conn = assign(conn, :org_id, org_id)
        assign(conn, :supabase_org_id, supabase_org_id)

      {:ok, %Tesla.Env{status: 500, body: %{"message" => "Unauthorized"}}} ->
        conn |> not_authorized_with_redirect()

      {:ok, %Tesla.Env{status: 401}} ->
        conn |> not_authorized_with_redirect()

      {:ok, %Tesla.Env{status: 502}} ->
        conn |> not_authorized_with_redirect()

      {:ok, _} ->
        conn |> not_authorized_with_redirect()
    end
  end

  def sign_out(conn) do
    conn = fetch_session(conn)

    return_url =
      case get_session(conn)["return_url"] do
        nil ->
          Supafana.env(:supafana_storefront_url)

        url ->
          url
      end

    conn
    |> configure_session(drop: true)
    |> put_resp_header("location", return_url)
    |> resp(:found, "")
  end

  def not_authorized_with_redirect(conn) do
    location = "Supafana.env(:supafana_storefront_url)/dashboard"

    conn
    |> resp(:found, "Not authorized")
    |> put_resp_header("location", location)
    |> halt()
  end
end
