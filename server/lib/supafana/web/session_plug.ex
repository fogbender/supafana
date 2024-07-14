defmodule Supafana.Plug.Session do
  import Plug.Conn
  import Supafana.Web.Utils

  def session() do
    Plug.Session.init(
      store: :cookie,
      key: "_store_session",
      same_site: "None",
      domain: nil,
      secure: true,
      # salts can be public, but it could be a good idea to change them from time to time
      encryption_salt: "ZjmoQndLh472tvMuGMXQ",
      signing_salt: "GTjm8F9hYGnLoWWU6qgW",
      log: :debug,
      # Set session for a month, in seconds
      max_age: 60 * 60 * 24 * 30
    )
  end

  def secret_key_base() do
    Supafana.env(:secret_key_base)
  end

  def init(opts) do
    session = session()
    Keyword.merge([session: session], opts)
  end

  def call(conn, opts) do
    conn =
      put_in(
        conn.secret_key_base,
        secret_key_base()
      )

    conn = Plug.Session.call(conn, opts[:session])

    if opts[:perform_manual_login] do
      conn
    else
      require_login(conn, opts)
    end
  end

  defp require_login(conn, opts) do
    conn = fetch_session(conn)
    supabase_refresh_token = get_session(conn, :supabase_refresh_token)

    conn = Supafana.Web.AuthUtils.handle_auth(conn, supabase_refresh_token)
    conn |> require_org_id(opts)
  end

  defp require_org_id(conn, _opts) do
    org_id = conn.assigns[:org_id]

    if org_id do
      conn
    else
      conn |> not_authorized()
    end
  end
end
