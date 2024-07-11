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

  get "fogbender-token" do
    conn = fetch_session(conn)
    organization_slug = get_session(conn)["organization_slug"]
    me = get_session(conn)["me"]
    widget_id = Supafana.env(:fogbender_widget_id)

    {:ok, %{status: 200, body: token}} =
      Supafana.Fogbender.Api.tokens(organization_slug, me["email"], me["user_id"])

    conn |> ok_json(Map.merge(token, %{"widgetId" => widget_id}))
  end

  get "/me" do
    conn = fetch_session(conn)
    me = get_session(conn)["me"]
    conn |> ok_json(me)
  end

  post "/probe-email-verification-code" do
    code = conn.params["verificationCode"]
    user_id = conn.params["userId"]

    case {code, user_id} do
      {code, user_id} when is_binary(code) and is_binary(code) ->
        conn = fetch_session(conn)
        verification_code = get_session(conn)["email_verification_code"]

        case verification_code do
          ^code ->
            email = get_session(conn)["email_candidate"]
            conn = Plug.Conn.put_session(conn, :me, %{"email" => email, "user_id" => user_id})
            ok_no_content(conn)

          _ ->
            verification_attempts = get_session(conn)["email_verification_attempts"] || 0

            conn =
              Plug.Conn.put_session(conn, :email_verification_attempts, verification_attempts + 1)

            Process.sleep(verification_attempts)
            send_resp(conn, 400, "verificationCode does not match")
        end

      _ ->
        send_resp(conn, 400, "Missing or malformed parameter: verificationCode")
    end
  end

  post "/send-email-verification-code" do
    email = conn.params["email"]

    case email do
      email when is_binary(email) ->
        verification_code = :rand.uniform(9) * 100 + :rand.uniform(9) * 10 + :rand.uniform(9)
        tx_id = "clydmxebf00c6q1v1dbmdnqyk"

        case Supafana.Loops.Api.send_tx(
               tx_id,
               email,
               %{
                 "verificationCode" => "#{verification_code}"
               }
             ) do
          {:ok, %Tesla.Env{status: 200}} ->
            conn = fetch_session(conn)
            conn = Plug.Conn.put_session(conn, :email_verification_code, "#{verification_code}")
            conn = Plug.Conn.put_session(conn, :email_candidate, email)
            ok_no_content(conn)

          {:ok,
           %Tesla.Env{status: 400, body: %{"error" => %{"message" => "Invalid email address"}}}} ->
            send_resp(conn, 400, "Invalid email address")

          {:ok, _} ->
            send_resp(conn, 400, "Unknown error")
        end

      _ ->
        send_resp(conn, 400, "Missing or malformed parameter: email")
    end
  end

  get "/organizations/:slug/members" do
    conn = fetch_session(conn)

    conn = Plug.Conn.put_session(conn, :organization_slug, slug)

    access_token = conn.assigns[:supabase_access_token]

    show_emails = conn.params["showEmails"]

    {:ok, members} = Supafana.Supabase.Management.organization_members(access_token, slug)

    case show_emails do
      "false" ->
        conn |> ok_json(members |> Enum.map(&(&1 |> Map.delete("email"))))

      _ ->
        conn |> ok_json(members)
    end
  end

  get "/organizations" do
    case conn.assigns[:supabase_access_token] do
      nil ->
        conn |> Supafana.Web.AuthUtils.not_authorized()

      access_token ->
        {:ok, organizations} = Supafana.Supabase.Management.organizations(access_token)
        conn |> ok_json(organizations)
    end
  end

  get "/projects" do
    access_token = conn.assigns[:supabase_access_token]

    {:ok, projects} = Supafana.Supabase.Management.projects(access_token)

    api_keys =
      projects
      |> Enum.filter(&(&1["status"] === "ACTIVE_HEALTHY"))
      |> Enum.map(fn p ->
        %{"id" => project_ref} = p

        project_api_keys =
          case Supafana.Supabase.Management.project_api_keys(access_token, project_ref) do
            {:ok, %{status: 200, body: body}} ->
              body

            _ ->
              :error
          end

        project_api_keys
      end)

    IO.inspect(api_keys)

    conn |> ok_json(projects)
  end

  defp ok_json(conn, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, data |> Jason.encode!(pretty: true))
  end

  defp ok_no_content(conn) do
    conn |> send_resp(204, "")
  end
end
