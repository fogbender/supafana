defmodule Supafana.Grafana.Api do
  require Logger

  def set_alert(url, alert) do
    r =
      client(url, [{"X-Disable-Provenance", "true"}])
      |> Tesla.post(
        "/api/v1/provisioning/alert-rules",
        alert
      )

    case r do
      {:ok, %Tesla.Env{status: 201, body: body}} ->
        {:ok, body}

      {:ok, %Tesla.Env{status: 400, body: %{"message" => "[alerting.alert-rule.conflict]" <> _}}} =
          body ->
        {:ok, body}
    end
  end

  def delete_alert(url, uid) do
    r =
      client(url)
      |> Tesla.delete("/api/v1/provisioning/alert-rules/#{uid}")

    case r do
      {:ok, %Tesla.Env{status: 204}} ->
        :ok
    end
  end

  def get_alert_definitions(url) do
    r =
      client(url)
      |> Tesla.get("/api/v1/provisioning/alert-rules")

    case r do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}
    end
  end

  def get_folders(url) do
    r =
      client(url)
      |> Tesla.get("/api/folders")

    case r do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}
    end
  end

  def get_dashboards(url) do
    r =
      client(url)
      |> Tesla.get("/api/search?query=&type=dash-db")

    case r do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}
    end
  end

  def get_datasources(url) do
    r =
      client(url)
      |> Tesla.get("/api/datasources")

    case r do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}
    end
  end

  def get_prometheus_datasource_id(url) do
    {:ok, [%{"name" => "prometheus", "uid" => uid}]} = get_datasources(url)
    {:ok, uid}
  end

  def create_folder(url, name) do
    r =
      client(url)
      |> Tesla.post(
        "/api/folders",
        %{
          "title" => name
        }
      )

    case r do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}
    end
  end

  def delete_folder(url, uid) do
    r =
      client(url)
      |> Tesla.delete("/api/folders/#{uid}")

    case r do
      {:ok, %Tesla.Env{status: 200}} ->
        :ok
    end
  end

  def get_contact_points(url) do
    r =
      client(url)
      |> Tesla.get("/api/v1/provisioning/contact-points")

    case r do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}
    end
  end

  def delete_contact_point(url, uid) do
    r =
      client(url)
      |> Tesla.delete("/api/v1/provisioning/contact-points/#{uid}")

    case r do
      {:ok, %Tesla.Env{status: 202}} ->
        :ok
    end
  end

  def add_contact_point_email(url, email) do
    :ok = update_email_contact_point(url, email, :add)
    :ok = create_grafana_email_policy(url)
  end

  def delete_contact_point_email(url, email) do
    update_email_contact_point(url, email, :remove)
  end

  def update_email_contact_point(url, email, operation) when operation in [:add, :remove] do
    {:ok, contact_points} = get_contact_points(url)

    email_contact_point =
      contact_points
      |> Enum.find(
        %{
          "name" => "supafana-email",
          "type" => "email",
          "settings" => %{
            "addresses" => "",
            "singleEmail" => true
          }
        },
        &(&1["name"] === "supafana-email")
      )

    %{"settings" => %{"addresses" => existing_addresses}} = email_contact_point

    emails =
      existing_addresses
      |> String.split([",", ";"])
      |> Enum.filter(&(String.length(&1 |> String.trim()) > 0))
      |> Enum.uniq()

    new_emails =
      case operation do
        :add ->
          [email | emails] |> Enum.filter(&(&1 !== "example@email.com"))

        :remove ->
          case emails |> Enum.filter(&(&1 !== email)) do
            [] ->
              ["example@email.com"]

            x ->
              x
          end
      end
      |> Enum.join(";")

    new_email_contact_point =
      Map.merge(email_contact_point, %{
        "settings" => %{
          "addresses" => new_emails,
          "singleEmail" => true
        }
      })

    r =
      case new_email_contact_point do
        %{"uid" => uid} ->
          client(url, [{"X-Disable-Provenance", "true"}])
          |> Tesla.put(
            "/api/v1/provisioning/contact-points/#{uid}",
            new_email_contact_point
          )

        _ ->
          client(url, [{"X-Disable-Provenance", "true"}])
          |> Tesla.post(
            "/api/v1/provisioning/contact-points",
            new_email_contact_point
          )
      end

    case r do
      {:ok, %Tesla.Env{status: 202}} ->
        :ok

      _ ->
        Logger.error("update_email_contact_point failed with #{inspect(r)}")
        :error
    end
  end

  def create_grafana_email_policy(url) do
    {:ok, policy} = get_policies(url)

    routes = policy |> Map.get("routes", [])

    new_routes =
      case routes |> Enum.find(&(&1["receiver"] === "supafana-email")) do
        nil ->
          [
            %{
              "object_matchers" => [["severity", "=", "critical"]],
              "provenance" => "api",
              "receiver" => "supafana-email"
            }
            | routes
          ]

        _ ->
          routes
      end

    new_policy = Map.merge(policy, %{"routes" => new_routes})

    r =
      client(url, [{"X-Disable-Provenance", "true"}])
      |> Tesla.put(
        "/api/v1/provisioning/policies",
        new_policy
      )

    case r do
      {:ok, %Tesla.Env{status: 202}} ->
        :ok
    end
  end

  def get_policies(url) do
    r =
      client(url)
      |> Tesla.get("/api/v1/provisioning/policies")

    case r do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}
    end
  end

  def delete_policy(url, email) do
    {:ok, policies} = get_policies(url)

    routes = policies |> Map.get("routes", [])

    policy_to_delete = %{
      "object_matchers" => [["severity", "=", "critical"]],
      "provenance" => "api",
      "receiver" => email
    }

    new_routes = routes |> List.delete(policy_to_delete)

    new_policy = Map.merge(policies, %{"routes" => new_routes})

    r =
      client(url, [{"X-Disable-Provenance", "true"}])
      |> Tesla.put(
        "/api/v1/provisioning/policies",
        new_policy
      )

    case r do
      {:ok, %Tesla.Env{status: 202}} ->
        :ok

      {:ok, %Tesla.Env{status: 404}} ->
        :ok
    end
  end

  def delete_policies(url) do
    r =
      client(url)
      |> Tesla.delete("/api/v1/provisioning/policies")

    case r do
      {:ok, %Tesla.Env{status: 202, body: body}} ->
        {:ok, body}
    end
  end

  defp client(base_url, headers \\ []) do
    base_url = {Tesla.Middleware.BaseUrl, base_url}
    json = Tesla.Middleware.JSON
    form = Tesla.Middleware.FormUrlencoded
    query = Tesla.Middleware.Query

    headers =
      {Tesla.Middleware.Headers,
       [
         {
           "accept",
           "application/json"
         }
       ] ++ headers}

    _x = """
    retry =
      {Tesla.Middleware.Retry,
       [
         delay: 1000,
         max_retries: 5,
         max_delay: 4_000,
         should_retry: fn
           {:ok, %{status: status}} when status in [500] -> true
           {:ok, _} -> false
           {:error, :timeout} -> true
           {:error, _} -> false
         end
       ]}
    """

    middleware = [base_url, json, form, query, headers]

    Tesla.client(middleware)
  end
end
