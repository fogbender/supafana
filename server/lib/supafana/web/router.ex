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
    organization_slug = conn.assigns[:supabase_org_id]
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

  post "/email-notifications/:user_id" do
    org_id = conn.assigns[:org_id]
    me = get_session(conn)["me"]

    tx_emails_enabled = conn.params["txEmailsEnabled"]

    Process.sleep(1000)

    update = fn ->
      Data.UserNotification.new(%{
        org_id: org_id,
        user_id: user_id,
        email: "N/A",
        tx_emails: tx_emails_enabled || false
      })
      |> Repo.insert!(
        on_conflict: {:replace, [:tx_emails]},
        conflict_target: [:org_id, :user_id]
      )
    end

    case me do
      %{"role_name" => role} when role in ["Owner", "Administrator"] ->
        %Data.UserNotification{} = update.()
        ok_no_content(conn)

      %{"user_id" => ^user_id} ->
        %Data.UserNotification{} = update.()
        ok_no_content(conn)

      _ ->
        send_resp(
          conn,
          400,
          "Only Owners and Administrators can update other’s notification settings"
        )
    end
  end

  get "/email-notifications" do
    org_id = conn.assigns[:org_id]

    data =
      from(
        n in Data.UserNotification,
        where: n.org_id == ^org_id
      )
      |> Repo.all()

    notifications =
      data
      |> Enum.map(fn n ->
        %Z.UserNotification{
          org_id: n.org_id,
          user_id: n.user_id,
          email: n.email,
          tx_emails: n.tx_emails
        }
      end)

    conn |> ok_json(notifications)
  end

  post "/probe-email-verification-code" do
    code = conn.params["verificationCode"]
    user_id = conn.params["userId"]

    error = fn message ->
      verification_attempts = get_session(conn)["email_verification_attempts"] || 0

      conn =
        Plug.Conn.put_session(conn, "email_verification_attempts", verification_attempts + 1)

      Process.sleep(verification_attempts)
      send_resp(conn, 400, message)
    end

    case {code, user_id} do
      {code, user_id} when is_binary(code) and is_binary(code) ->
        conn = fetch_session(conn)
        verification_code = get_session(conn)["email_verification_code"]

        case verification_code do
          ^code ->
            email = get_session(conn)["email_candidate"]

            access_token = conn.assigns[:supabase_access_token]
            organization_slug = conn.assigns[:supabase_org_id]

            {:ok, members} =
              Supafana.Supabase.Management.organization_members(access_token, organization_slug)

            user = members |> Enum.find(&(&1["user_id"] == user_id))

            case user["email"] do
              ^email ->
                conn = Plug.Conn.put_session(conn, "me", user)

                ok_no_content(conn)

              _ ->
                error.("email and user_id do not match")
            end

          _ ->
            error.("verificationCode does not match")
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
            conn = Plug.Conn.put_session(conn, "email_verification_code", "#{verification_code}")
            conn = Plug.Conn.put_session(conn, "email_candidate", email)
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
    access_token = conn.assigns[:supabase_access_token]

    show_emails = conn.params["showEmails"]

    {:ok, members} = Supafana.Supabase.Management.organization_members(access_token, slug)

    org_id = conn.assigns[:org_id]

    {_, _} =
      Repo.insert_all(
        Data.UserNotification,
        members
        |> Enum.filter(&(not is_nil(&1["email"])))
        |> Enum.map(fn m ->
          %{
            org_id: org_id,
            user_id: m["user_id"],
            email: m["email"],
            inserted_at: DateTime.utc_now(),
            updated_at: DateTime.utc_now()
          }
        end),
        on_conflict: :nothing,
        conflict_target: [:org_id, :user_id]
      )

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
        case Supafana.Azure.Api.check_deployment(project_ref) do
          {:ok, %{"properties" => %{"provisioningState" => "Failed"}}} ->
            :ok = Supafana.Azure.Api.delete_vm(project_ref)

          _ ->
            :ok
        end

        %Data.Grafana{} =
          Repo.Grafana.set_state(project_ref, org_id, "Provisioning")

        password = Supafana.Password.generate()

        %Data.Grafana{} =
          Repo.Grafana.set_password(project_ref, org_id, password)

        case Supafana.Azure.Api.create_deployment(project_ref, service_key, password) do
          {:ok, %{"properties" => %{"provisioningState" => "Accepted"}}} ->
            Logger.info("#{project_ref}: Accepted")
            :ok

          {:error, %{"error" => %{"code" => "DeploymentActive"}}} ->
            Logger.info("#{project_ref}: DeploymentActive")
            :ok
        end

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
        Supafana.Web.Task.schedule(
          operation: :delete_vm,
          project_ref: project_ref,
          org_id: org_id
        )

        ok_no_content(conn)
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
      inserted_at: to_unix(g.inserted_at),
      updated_at: to_unix(g.updated_at),
      first_start_at: to_unix(g.first_start_at),
      password: g.password,
      trial_length_min: Supafana.env(:trial_length_min),
      trial_remaining_msec:
        case g.first_start_at do
          nil ->
            nil

          first_start_at ->
            to_unix(first_start_at) + Supafana.env(:trial_length_min) * 60 * 1000 -
              (DateTime.now("Etc/UTC") |> elem(1) |> DateTime.to_unix(:millisecond))
        end
    }
    |> Z.Grafana.to_json!()
    |> Z.Grafana.from_json!()
  end
end
