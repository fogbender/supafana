defmodule Supafana.Azure.Api do
  require Logger
  alias Supafana.Azure

  def list_resources_by_tag(tag) do
    {:ok, access_token} = Azure.Auth.api_access_token()

    subscription_id = Supafana.env(:azure_subscription_id)

    path = "/subscriptions/#{subscription_id}/resources"

    r =
      client_with_retry(access_token)
      |> Tesla.get(path,
        query: [
          {"$filter", "tagName eq 'vm' and tagValue eq '#{tag}'"},
          {"api-version", "2021-04-01"}
        ]
      )

    case r do
      {:ok, %Tesla.Env{status: 200, body: %{"value" => resources}}} ->
        {:ok, resources}

      {:ok,
       %Tesla.Env{
         status: 401,
         body: %{
           "error" => %{
             "code" => code
           }
         }
       }}
      when code in ["ExpiredAuthenticationToken", "InvalidAuthenticationToken"] ->
        {:ok, _} = Azure.Auth.api_access_token(:renew)
        list_resources_by_tag(tag)
    end
  end

  def check_vm(project_ref) do
    subscription_id = Supafana.env(:azure_subscription_id)
    resource_group = Supafana.env(:azure_resource_group)
    supafana_env = Supafana.env(:supafana_env)
    vm_name = "supafana-#{supafana_env}-grafana-#{project_ref}"

    path =
      "/subscriptions/#{subscription_id}/resourceGroups/#{resource_group}/providers/Microsoft.Compute/virtualMachines/#{vm_name}/InstanceView"

    {:ok, access_token} = Azure.Auth.api_access_token()

    r =
      client_with_retry(access_token)
      |> Tesla.get(path,
        query: [
          {"api-version", "2021-04-01"}
        ]
      )

    case r do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Tesla.Env{status: 404}} ->
        {:error, :not_found}

      {:ok,
       %Tesla.Env{
         status: 401,
         body: %{
           "error" => %{
             "code" => code
           }
         }
       }}
      when code in ["ExpiredAuthenticationToken", "InvalidAuthenticationToken"] ->
        {:ok, _} = Azure.Auth.api_access_token(:renew)
        check_vm(project_ref)
    end
  end

  def delete_vm(project_ref) do
    subscription_id = Supafana.env(:azure_subscription_id)
    resource_group = Supafana.env(:azure_resource_group)
    supafana_env = Supafana.env(:supafana_env)
    vm_name = "supafana-#{supafana_env}-grafana-#{project_ref}"

    path =
      "/subscriptions/#{subscription_id}/resourceGroups/#{resource_group}/providers/Microsoft.Compute/virtualMachines/#{vm_name}"

    {:ok, access_token} = Azure.Auth.api_access_token()

    r =
      client_with_retry(access_token)
      |> Tesla.delete(path,
        query: [
          {"api-version", "2021-04-01"}
        ]
      )

    case r do
      {:ok, %Tesla.Env{status: status}} when status in [201, 202, 204] ->
        case check_vm(project_ref) do
          {:error, :not_found} ->
            delete_resources_by_tag(vm_name)

          _ ->
            Logger.info("VM #{project_ref} is still around, waiting for deletion...")
            Process.sleep(2000)
            delete_vm(project_ref)
        end

      {:ok, %Tesla.Env{status: 409}} ->
        # {"code" => "Conflict", "message" => "The request failed due to conflict with a concurrent request. To resolve it, please refer to https://aka.ms/activitylog to get more details on the conflicting requests."}
        r

      {:ok,
       %Tesla.Env{
         status: 401,
         body: %{
           "error" => %{
             "code" => code
           }
         }
       }}
      when code in ["ExpiredAuthenticationToken", "InvalidAuthenticationToken"] ->
        {:ok, _} = Azure.Auth.api_access_token(:renew)
        delete_vm(project_ref)
    end
  end

  def delete_resources_by_tag(tag) do
    {:ok, resources} = list_resources_by_tag(tag)

    delete_resources(resources)
  end

  defp delete_resources([]) do
    :ok
  end

  defp delete_resources([%{"id" => id} = h | t] = resources) do
    {:ok, access_token} = Azure.Auth.api_access_token()

    path = "/#{id}"

    r =
      client_with_retry(access_token)
      |> Tesla.delete(path,
        query: [
          {"api-version", "2021-04-01"}
        ]
      )

    case r do
      {:ok, %Tesla.Env{status: status}} when status in [201, 202, 204] ->
        Logger.info("Deleted #{id}")
        delete_resources(t)

      {:ok, %Tesla.Env{status: status}} when status in [400] ->
        Logger.info("Resource #{id} has dependencies, deleting others first")
        delete_resources(t ++ [h])

      {:ok, %Tesla.Env{status: status}} when status in [409] ->
        Logger.info("Resource #{id} has dependencies, deleting others first")
        delete_resources(t ++ [h])

      {:ok,
       %Tesla.Env{
         status: 429,
         body: %{"error" => %{"code" => "RetryableError", "message" => message}}
       }} ->
        Logger.info(message)
        Process.sleep(10000)
        delete_resources(resources)

      {:ok,
       %Tesla.Env{
         status: 401,
         body: %{
           "error" => %{
             "code" => code
           }
         }
       }}
      when code in ["ExpiredAuthenticationToken", "InvalidAuthenticationToken"] ->
        {:ok, _} = Azure.Auth.api_access_token(:renew)
        delete_resources(resources)
    end
  end

  def check_deployment(project_ref) do
    {:ok, access_token} = Azure.Auth.api_access_token()

    path = deployment_path(project_ref)

    r =
      client_with_retry(access_token)
      |> Tesla.get(path)

    case r do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}

      {:ok,
       %Tesla.Env{
         status: 401,
         body: %{
           "error" => %{
             "code" => code
           }
         }
       }}
      when code in ["ExpiredAuthenticationToken", "InvalidAuthenticationToken"] ->
        {:ok, _} = Azure.Auth.api_access_token(:renew)
        check_deployment(project_ref)

      resp ->
        resp
    end
  end

  def create_deployment(project_ref, project_name, service_role_key, password) do
    supafana_domain = Supafana.env(:supafana_domain)
    supafana_env = Supafana.env(:supafana_env)

    smtp_host = Supafana.env(:smtp_host)
    smtp_user = Supafana.env(:smtp_user)
    smtp_password = Supafana.env(:smtp_password)
    smtp_from_address = Supafana.env(:smtp_from_address)

    parameters = %{
      "supabaseProjectRef" => %{
        "value" => project_ref
      },
      "supabaseProjectName" => %{
        "value" => project_name
      },
      "supabaseServiceRoleKey" => %{
        "value" => service_role_key
      },
      "supafanaDomain" => %{
        "value" => supafana_domain
      },
      "grafanaPassword" => %{
        "value" => password
      },
      "env" => %{
        "value" => supafana_env
      },
      "smtpHost" => %{
        "value" => smtp_host
      },
      "smtpUser" => %{
        "value" => smtp_user
      },
      "smtpPassword" => %{
        "value" => smtp_password
      },
      "smtpFromAddress" => %{
        "value" => smtp_from_address
      }
    }

    {:ok, access_token} = Azure.Auth.api_access_token()

    path = deployment_path(project_ref)

    r =
      client_with_retry(access_token)
      |> Tesla.put(path, %{
        "properties" => %{
          "templateLink" => %{
            "id" => Azure.TemplateSpec.grafana()
          },
          "parameters" => parameters,
          "mode" => "Incremental"
        }
      })

    case r do
      {:ok, %Tesla.Env{status: 201, body: body}} ->
        {:ok, body}

      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Tesla.Env{status: 409, body: %{"error" => %{"code" => "DeploymentActive"}} = body}} ->
        {:error, body}

      {:ok,
       %Tesla.Env{
         status: 401,
         body: %{
           "error" => %{
             "code" => code
           }
         }
       }}
      when code in ["ExpiredAuthenticationToken", "InvalidAuthenticationToken"] ->
        {:ok, _} = Azure.Auth.api_access_token(:renew)
        create_deployment(project_ref, project_name, service_role_key, password)
    end
  end

  defp deployment_path(project_ref) do
    subscription_id = Supafana.env(:azure_subscription_id)
    resource_group = Supafana.env(:azure_resource_group)
    deployment_name = "grafana-deployment-#{project_ref}"

    "/subscriptions/#{subscription_id}/resourcegroups/#{resource_group}/providers/Microsoft.Resources/deployments/#{deployment_name}?api-version=2021-04-01"
  end

  def client(access_token) do
    url = "https://management.azure.com"
    base_url = {Tesla.Middleware.BaseUrl, url}
    json = Tesla.Middleware.JSON
    query = Tesla.Middleware.Query

    headers =
      {Tesla.Middleware.Headers,
       [
         {
           "content-type",
           "application/json"
         },
         {
           "authorization",
           "Bearer #{access_token}"
         },
         {
           "accept",
           "*/*"
         }
       ]}

    middleware = [base_url, json, query, headers]

    Tesla.client(middleware)
  end

  defp client_with_retry(access_token, extra_headers \\ []) do
    url = "https://management.azure.com"
    base_url = {Tesla.Middleware.BaseUrl, url}
    json = Tesla.Middleware.JSON
    query = Tesla.Middleware.Query

    headers =
      {Tesla.Middleware.Headers,
       [
         {
           "content-type",
           "application/json"
         },
         {
           "authorization",
           "Bearer #{access_token}"
         },
         {
           "accept",
           "*/*"
         }
       ] ++ extra_headers}

    retry =
      {Tesla.Middleware.Retry,
       [
         delay: 1000,
         max_retries: 10,
         max_delay: 4_000,
         should_retry: fn
           {:ok, %{status: status}} when status in [429, 500] -> true
           {:ok, _} -> false
           {:error, :timeout} -> true
           {:error, _} -> true
         end
       ]}

    middleware = [base_url, json, query, headers, retry]

    Tesla.client(middleware)
  end
end
