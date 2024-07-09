defmodule Supafana.Web.AuthUtils do
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
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(401, Jason.encode!(%{"error" => "not authorized"}))
    |> Plug.Conn.halt()
  end

  defp handle_tokens(conn, tokens) do
    %{
      "access_token" => access_token,
      "refresh_token" => refresh_token
    } = tokens

    conn = Plug.Conn.put_session(conn, :supabase_access_token, access_token)
    conn = Plug.Conn.put_session(conn, :supabase_refresh_token, refresh_token)
    Plug.Conn.assign(conn, :supabase_access_token, access_token)
  end
end
