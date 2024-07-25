defmodule Supafana.Web.AuthRouter do
  use Plug.Router

  plug(:match)
  plug(:fetch_query_params)

  plug(Supafana.Plug.Session, perform_manual_login: true)
  plug(:store_data_before_redirect)
  plug(:dispatch)

  defp store_data_before_redirect(conn, _opts) do
    case conn.path_info do
      ["supabase-connect"] ->
        return_url =
          with return_url when is_binary(return_url) <- conn.query_params["returnUrl"],
               [referer] when is_binary(referer) <- get_req_header(conn, "referer"),
               %URI{authority: same_authority} <- URI.parse(return_url),
               %URI{authority: ^same_authority} <- URI.parse(referer) do
            return_url
          end

        if return_url do
          conn = fetch_session(conn)
          conn = put_session(conn, :return_url, return_url)
          conn
        else
          conn = send_resp(conn, 400, "returnUrl and referer do not match")
          conn |> halt()
        end

      _ ->
        conn
    end
  end

  post "/sign-out" do
    Supafana.Web.AuthUtils.sign_out(conn)
  end

  post "/supabase-connect" do
    verifier = :crypto.strong_rand_bytes(64) |> Base.url_encode64(padding: false)
    challenge = :crypto.hash(:sha256, verifier) |> Base.url_encode64(padding: false)
    conn = fetch_session(conn)
    conn = put_session(conn, :supabase_verifier, verifier)

    search =
      URI.encode_query(
        %{
          client_id: Supafana.env(:supabase_client_id),
          redirect_uri: redirect_uri(),
          response_type: "code",
          code_challenge: challenge,
          code_challenge_method: "S256"
        },
        :rfc3986
      )

    url = URI.parse("https://api.supabase.com/v1/oauth/authorize?#{search}") |> to_string()

    if conn.state == :sent do
      conn
    else
      conn
      |> resp(:found, "")
      |> put_resp_header("location", url)
    end
  end

  get "/supabase" do
    conn = fetch_session(conn)

    return_url =
      case get_session(conn)["return_url"] do
        nil ->
          "#{Supafana.env(:supafana_storefront_url)}/dashboard"

        url ->
          url
      end

    code_verifier = get_session(conn)["supabase_verifier"]

    code = conn.query_params["code"]
    redirect_uri = redirect_uri()

    conn = Supafana.Web.AuthUtils.handle_auth(conn, code, redirect_uri, code_verifier)

    if conn.state == :sent do
      conn
    else
      conn
      |> resp(:found, "")
      |> put_resp_header("location", return_url)
    end
  end

  defp redirect_uri(), do: "#{Supafana.env(:supafana_api_url)}/api/auth/supabase"
end
