defmodule Supafana.Web.Router do
  import Supafana.Web.Utils

  import Ecto.Query, only: [from: 2]

  require Logger

  use Plug.Router

  alias Supafana.{Data, Grafana, Repo, Utils, Z}

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

  post "/grafanas/:project_ref" do
    access_token = conn.assigns[:supabase_access_token]

    case ensure_own_project(access_token, project_ref) do
      false ->
        forbid(conn, "Project #{project_ref} does not belong to your Supabase organization")

      {:ok, _} ->
        max_client_connections = conn.params["maxClientConnections"]

        case max_client_connections do
          x when is_integer(x) ->
            Process.sleep(1000)

            Data.Grafana
            |> Repo.get_by(supabase_id: project_ref)
            |> Data.Grafana.update(max_client_connections: x)
            |> Repo.update!()

            {:ok, grafana_api_access_url, _, _, _} = get_grafana_api_params(project_ref)

            {:ok, alert_definitions} = Grafana.Api.get_alert_definitions(grafana_api_access_url)

            case alert_definitions |> Enum.find(&(&1["title"] == "Connection Count Alert")) do
              nil ->
                :ok

              %{"uid" => alert_uid} ->
                :ok = Grafana.Api.delete_alert(grafana_api_access_url, alert_uid)
            end

            conn |> ok_no_content()

          _ ->
            send_resp(
              conn,
              400,
              "Expected maxClientConnections parameter of type integer"
            )
        end
    end
  end

  post "/grafanas/:project_ref/alerts/:title" do
    access_token = conn.assigns[:supabase_access_token]

    case ensure_own_project(access_token, project_ref) do
      false ->
        forbid(conn, "Project #{project_ref} does not belong to your Supabase organization")

      {:ok, _} ->
        me = get_session(conn)["me"]
        enabled = conn.params["enabled"]

        update = fn ->
          %Data.Grafana{id: grafana_id} =
            from(
              g in Data.Grafana,
              where: g.supabase_id == ^project_ref
            )
            |> Repo.one!()

          Data.Alert.new(%{
            grafana_id: grafana_id,
            supabase_id: project_ref,
            title: title,
            enabled: enabled
          })
          |> Repo.insert!(
            on_conflict: {:replace, [:enabled]},
            conflict_target: [:grafana_id, :title]
          )

          :ok
        end

        case me do
          %{"role_name" => role} when role in ["Owner", "Administrator"] ->
            update.()
            ok_no_content(conn)

          _ ->
            send_resp(
              conn,
              400,
              "Only Owners and Administrators can update alerts"
            )
        end
    end
  end

  get "/grafanas/:project_ref/alerts" do
    access_token = conn.assigns[:supabase_access_token]

    case ensure_own_project(access_token, project_ref) do
      false ->
        forbid(conn, "Project #{project_ref} does not belong to your Supabase organization")

      {:ok, _} ->
        {:ok, grafana_api_access_url, grafana, folder_uid, prometheus_uid} =
          get_grafana_api_params(project_ref)

        case {folder_uid, prometheus_uid} do
          {nil, _} ->
            forbid(conn, "Project #{project_ref} does not have an Alerts folder")

          {_, nil} ->
            forbid(conn, "Project #{project_ref} does not have a Prometheus data source")

          _ ->
            {:ok, alert_definitions} = Grafana.Api.get_alert_definitions(grafana_api_access_url)

            alert_specs =
              Grafana.Alerts.specs(
                project_ref,
                folder_uid,
                prometheus_uid,
                grafana.max_client_connections
              )

            alert_titles = alert_specs |> Enum.map(& &1["title"])

            {_, _} =
              Repo.insert_all(
                Data.Alert,
                alert_specs
                |> Enum.map(fn alert ->
                  %{
                    grafana_id: grafana.id,
                    supabase_id: project_ref,
                    title: alert["title"],
                    inserted_at: DateTime.utc_now(),
                    updated_at: DateTime.utc_now()
                  }
                end),
                on_conflict: :nothing,
                conflict_target: [:grafana_id, :title]
              )

            active_alerts =
              from(
                a in Data.Alert,
                where: a.grafana_id == ^grafana.id,
                where: a.enabled == true and a.title in ^alert_titles
              )
              |> Repo.all()

            active_alerts
            |> Enum.each(fn %{title: title} ->
              if is_nil(alert_definitions |> Enum.find(&(&1["title"] == title))) do
                spec = alert_specs |> Enum.find(&(&1["title"] == title))
                {:ok, _} = Grafana.Api.set_alert(grafana_api_access_url, spec)
              end
            end)

            inactive_alerts =
              from(
                a in Data.Alert,
                where: a.grafana_id == ^grafana.id,
                where: a.enabled == false or a.title not in ^alert_titles
              )
              |> Repo.all()

            inactive_alerts
            |> Enum.each(fn %{title: title} ->
              case alert_definitions |> Enum.find(&(&1["title"] == title)) do
                nil ->
                  :ok

                %{"uid" => uid} ->
                  Grafana.Api.delete_alert(grafana_api_access_url, uid)
              end
            end)

            alerts =
              from(
                a in Data.Alert,
                where: a.grafana_id == ^grafana.id
              )
              |> Repo.all()

            conn
            |> ok_json(
              alerts
              |> Enum.map(fn a ->
                %Z.Alert{
                  title: a.title,
                  enabled: a.enabled
                }
              end)
            )
        end
    end
  end

  post "/grafanas/:project_ref/email-alert-contacts/:email" do
    access_token = conn.assigns[:supabase_access_token]

    case ensure_own_project(access_token, project_ref) do
      false ->
        forbid(conn, "Project #{project_ref} does not belong to your Supabase organization")

      {:ok, _} ->
        me = get_session(conn)["me"]
        enabled = conn.params["enabled"]

        update = fn ->
          %Data.Grafana{id: grafana_id, password: password} =
            from(
              g in Data.Grafana,
              where: g.supabase_id == ^project_ref
            )
            |> Repo.one!()

          Data.EmailAlertContact.new(%{
            grafana_id: grafana_id,
            supabase_id: project_ref,
            email: email,
            severity:
              case enabled do
                true ->
                  "critical"

                false ->
                  "none"
              end
          })
          |> Repo.insert!(
            on_conflict: {:replace, [:severity]},
            conflict_target: [:grafana_id, :email]
          )

          :ok = update_contact_point(password, project_ref, email, enabled)
        end

        case me do
          %{"role_name" => role} when role in ["Owner", "Administrator"] ->
            update.()
            ok_no_content(conn)

          %{"email" => ^email} ->
            update.()
            ok_no_content(conn)

          _ ->
            send_resp(
              conn,
              400,
              "Only Owners and Administrators can update alert contacts for others"
            )
        end
    end
  end

  get "/grafanas/:project_ref/email-alert-contacts" do
    access_token = conn.assigns[:supabase_access_token]

    case ensure_own_project(access_token, project_ref) do
      false ->
        forbid(conn, "Project #{project_ref} does not belong to your Supabase organization")

      {:ok, _} ->
        data =
          from(
            n in Data.EmailAlertContact,
            where: n.supabase_id == ^project_ref
          )
          |> Repo.all()

        email_alert_contacts =
          data
          |> Enum.map(fn c ->
            %Z.EmailAlertContact{
              email: c.email,
              severity: c.severity
            }
          end)

        conn |> ok_json(email_alert_contacts)
    end
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

    project_emails = members |> Enum.filter(&(not is_nil(&1["email"]))) |> Enum.map(& &1["email"])

    from(
      g in Data.Grafana,
      where: g.org_id == ^org_id,
      where: g.state == "Running"
    )
    |> Repo.all()
    |> Enum.each(fn g ->
      {_, _} =
        Repo.insert_all(
          Data.EmailAlertContact,
          project_emails
          |> Enum.map(fn email ->
            %{
              grafana_id: g.id,
              supabase_id: g.supabase_id,
              email: email,
              severity: "critical",
              inserted_at: DateTime.utc_now(),
              updated_at: DateTime.utc_now()
            }
          end),
          on_conflict: :nothing,
          conflict_target: [:grafana_id, :email]
        )

      enabled_emails =
        from(
          c in Data.EmailAlertContact,
          where: c.grafana_id == ^g.id,
          where: c.severity == "critical",
          select: c.email
        )
        |> Repo.all()

      enabled_emails
      |> Enum.each(fn email ->
        :ok = update_contact_point(g.password, g.supabase_id, email, true)
      end)

      {_, deleted_members} =
        from(
          m in Data.EmailAlertContact,
          where: m.grafana_id == ^g.id,
          where: m.email not in ^project_emails,
          select: m
        )
        |> Repo.delete_all()

      deleted_members
      |> Enum.each(fn
        %Data.EmailAlertContact{email: email} when not is_nil(email) ->
          :ok = update_contact_point(g.password, g.supabase_id, email, false)

        _ ->
          :ok
      end)
    end)

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

        project_name =
          case Supafana.Supabase.Management.projects(access_token) do
            {:ok, projects} ->
              case projects |> Enum.find(&(&1["id"] === project_ref)) do
                project when not is_nil(project) ->
                  project["name"]
              end
          end

        password = Supafana.Password.generate()

        %Data.Grafana{} =
          Repo.Grafana.set_password(project_ref, org_id, password)

        case Supafana.Azure.Api.create_deployment(
               project_ref,
               project_name,
               service_key,
               password
             ) do
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
        end,
      max_client_connections: g.max_client_connections
    }
    |> Z.Grafana.to_json!()
    |> Z.Grafana.from_json!()
  end

  defp get_grafana_api_access_url(project_ref) do
    %Data.Grafana{password: password} =
      grafana =
      from(
        g in Data.Grafana,
        where: g.supabase_id == ^project_ref
      )
      |> Repo.one()

    {:ok, "https://admin:#{password}@#{Supafana.env(:supafana_domain)}/dashboard/#{project_ref}/",
     grafana}
  end

  defp update_contact_point(password, project_ref, email, enabled) do
    url = "https://admin:#{password}@#{Supafana.env(:supafana_domain)}/dashboard/#{project_ref}/"

    case enabled do
      true ->
        :ok = Grafana.Api.add_contact_point_email(url, email)

      false ->
        :ok = Grafana.Api.delete_contact_point_email(url, email)
    end
  end

  defp get_grafana_api_params(project_ref) do
    {:ok, grafana_api_access_url, grafana} = get_grafana_api_access_url(project_ref)

    {:ok, folders} = Grafana.Api.get_folders(grafana_api_access_url)

    folder_uid =
      case folders |> Enum.find(&(&1["title"] === "Alerts")) do
        nil ->
          {:ok, %{"uid" => uid}} = Grafana.Api.create_folder(grafana_api_access_url, "Alerts")
          uid

        %{"uid" => uid} ->
          uid
      end

    {:ok, datasources} = Grafana.Api.get_datasources(grafana_api_access_url)

    prometheus_uid =
      case datasources |> Enum.find(&(&1["name"] === "prometheus")) do
        nil ->
          nil

        %{"uid" => prometheus_uid} ->
          prometheus_uid
      end

    {:ok, grafana_api_access_url, grafana, folder_uid, prometheus_uid}
  end
end
