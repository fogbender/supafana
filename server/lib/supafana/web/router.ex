defmodule Supafana.Web.Router do
  import Supafana.Web.Utils
  import Ecto.Query, only: [from: 2]

  require Logger

  use Plug.Router

  alias Supafana.{Data, Repo, Utils, Z}

  plug(:match)

  plug(:fetch_query_params)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug(Supafana.Plug.Session)

  plug(:dispatch)

  get "/favicon.ico" do
    ok_no_content(conn)
  end

  get "/fogbender-signatures" do
    conn = fetch_session(conn)
    organization_slug = get_session(conn)["organization_slug"]
    me = get_session(conn)["me"]
    widget_id = Supafana.env(:fogbender_widget_id)

    {:ok, %{status: 200, body: signatures}} =
      Supafana.Fogbender.Api.tokens(organization_slug, me["email"], me["user_id"])

    # Fogbender API has bad naming -
    # should be /signatures instead of /token,
    # should return "signatures" => ... instead of "token => ...
    conn |> ok_json(%{"signatures" => signatures["token"], "widgetId" => widget_id})
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
        conn |> not_authorized()

      access_token ->
        case Supafana.Supabase.Management.organizations(access_token) do
          {:ok, %Tesla.Env{status: 200, body: organizations}} ->
            conn |> ok_json(organizations)

          {:ok, %Tesla.Env{status: 500, body: %{"message" => "Unauthorized"}}} ->
            Supafana.Web.AuthUtils.sign_out(conn)
        end
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

  get "/grafanas" do
    org_id = conn.assigns[:org_id]

    grafanas =
      from(
        g in Data.Grafana,
        where: g.org_id == ^org_id
      )
      |> Repo.all()
      |> Enum.map(fn g ->
        grafana_to_z_grafana(g)
      end)

    conn |> ok_json(grafanas)
  end

  put "/grafanas/:project_ref" do
    access_token = conn.assigns[:supabase_access_token]
    org_id = conn.assigns[:org_id]

    # NOTE we need to make sure this org actually owns project with project_ref
    case ensure_own_project(access_token, project_ref) do
      false ->
        forbid(conn, "Project #{project_ref} does not belong to your Supabase organization")

      {:ok, service_key} ->
        Repo.Grafana.set_grafana_state(project_ref, org_id, "Provisioning")

        case Supafana.Azure.Api.create_deployment(project_ref, service_key) do
          {:ok, %{"properties" => %{"provisioningState" => "Accepted"}}} ->
            IO.inspect("Accepted")
            :ok

          {:error, %{"error" => %{"code" => "DeploymentActive"}}} ->
            IO.inspect("DeploymentActive")
            :ok
        end

        state =
          case Supafana.Azure.Api.check_vm(project_ref) do
            {:error, :not_found} ->
              "Initializing"

            {:ok, %{"statuses" => statuses}} ->
              case statuses |> Enum.find(&(&1["code"] == "ProvisioningState/succeeded")) do
                nil ->
                  "Unknown"

                %{"code" => "ProvisioningState/succeeded"} ->
                  "Running"
              end

            _ ->
              "Unknown"
          end

        Repo.Grafana.set_grafana_state(project_ref, org_id, state)

        ok_no_content(conn)
    end
  end

  delete "/grafanas/:project_ref" do
    access_token = conn.assigns[:supabase_access_token]
    org_id = conn.assigns[:org_id]

    # NOTE we need to make sure this org actually owns project with project_ref
    case ensure_own_project(access_token, project_ref) do
      false ->
        forbid(conn, "Project #{project_ref} does not belong to your Supabase organization")

      {:ok, _} ->
        Repo.Grafana.set_grafana_state(project_ref, org_id, "Deleting")

        case Supafana.Azure.Api.delete_vm(project_ref) do
          :ok ->
            Repo.Grafana.set_grafana_state(project_ref, org_id, "Deleted")
        end

        ok_no_content(conn)
    end
  end

  defp ensure_own_project(access_token, project_ref) do
    case Supafana.Supabase.Management.project_api_keys(access_token, project_ref) do
      {:ok, %{status: 200, body: keys}} ->
        service_key = (keys |> Enum.find(&(&1["name"] == "service_role")))["api_key"]
        {:ok, service_key}

      _ ->
        false
    end
  end

  defp to_unix(nil), do: nil
  defp to_unix(us), do: Utils.to_unix(us)

  defp grafana_to_z_grafana(g) do
    %Z.Grafana{
      id: g.id,
      supabase_id: g.supabase_id,
      org_id: g.org_id,
      plan: g.plan,
      state: g.state,
      inserted_at: to_unix(g.inserted_at)
    }
    |> Z.Grafana.to_json!()
    |> Z.Grafana.from_json!()
  end
end
