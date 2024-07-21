defmodule Supafana.Azure.Api do
  require Logger

  def clear_access_token() do
    tenant_id = Supafana.env(:azure_tenant_id)

    true = :ets.delete(:azure_token_cache, {:graph_access_token, tenant_id})

    :ok
  end

  def get_graph_access_token(renew \\ false) do
    tenant_id = Supafana.env(:azure_tenant_id)

    renew_token = fn ->
      path = "/#{tenant_id}/oauth2/v2.0/token"
      client_id = Supafana.env(:azure_client_id)
      client_secret = Supafana.env(:azure_client_secret)

      r =
        client_jwt()
        |> Tesla.post(path, %{
          grant_type: "client_credentials",
          client_id: client_id,
          client_secret: client_secret,
          scope: "https://management.azure.com/.default"
        })

      case r do
        {:ok, %Tesla.Env{status: 200, body: %{"access_token" => access_token}}} ->
          true =
            :ets.insert(:azure_token_cache, {{:graph_access_token, tenant_id}, access_token})

          {:ok, access_token}
      end
    end

    case {renew, :ets.lookup(:azure_token_cache, {:graph_access_token, tenant_id})} do
      {_, []} ->
        renew_token.()

      {:renew, _} ->
        renew_token.()

      {false, [{{:graph_access_token, ^tenant_id}, token}]} ->
        {:ok, token}
    end
  end

  def list_resources_by_tag(tag) do
    {:ok, access_token} = get_graph_access_token()

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
        {:ok, _} = get_graph_access_token(:renew)
        list_resources_by_tag(tag)
    end
  end

  def check_vm(project_ref) do
    subscription_id = Supafana.env(:azure_subscription_id)
    resource_group = Supafana.env(:azure_resource_group)

    path =
      "/subscriptions/#{subscription_id}/resourceGroups/#{resource_group}/providers/Microsoft.Compute/virtualMachines/#{project_ref}/InstanceView"

    {:ok, access_token} = get_graph_access_token()

    r =
      client(access_token)
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
        {:ok, _} = get_graph_access_token(:renew)
        check_vm(project_ref)
    end
  end

  def delete_vm(project_ref) do
    subscription_id = Supafana.env(:azure_subscription_id)
    resource_group = Supafana.env(:azure_resource_group)

    path =
      "/subscriptions/#{subscription_id}/resourceGroups/#{resource_group}/providers/Microsoft.Compute/virtualMachines/#{project_ref}"

    {:ok, access_token} = get_graph_access_token()

    r =
      client(access_token)
      |> Tesla.delete(path,
        query: [
          {"api-version", "2021-04-01"}
        ]
      )

    case r do
      {:ok, %Tesla.Env{status: status}} when status in [201, 202, 204] ->
        case check_vm(project_ref) do
          {:error, :not_found} ->
            delete_resources_by_tag(project_ref)

          _ ->
            Logger.info("VM #{project_ref} is still around, waiting for deletion...")
            Process.sleep(2000)
            delete_vm(project_ref)
        end

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
        {:ok, _} = get_graph_access_token(:renew)
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
    {:ok, access_token} = get_graph_access_token()

    path = "/#{id}"

    r =
      client(access_token)
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
        {:ok, _} = get_graph_access_token(:renew)
        delete_resources(resources)
    end
  end

  def check_deployment(project_ref) do
    {:ok, access_token} = get_graph_access_token()

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
        {:ok, _} = get_graph_access_token(:renew)
        check_deployment(project_ref)
    end
  end

  def create_deployment(project_ref, service_role_key) do
    supafana_domain = Supafana.env(:supafana_domain)

    template_file_url = "https://biceps.blob.core.windows.net/biceps/grafana.json"

    template_file_query_string =
      "sp=r&st=2024-07-14T16:19:06Z&se=2027-01-01T01:19:06Z&spr=https&sv=2022-11-02&sr=c&sig=LOuF6bWvwEm37sDVLphqlQMiII19N6i6G%2F8NNXiPbuA%3D"

    parameters = %{
      "supabaseProjectRef" => %{
        "value" => project_ref
      },
      "supabaseServiceRoleKey" => %{
        "value" => service_role_key
      },
      "supafanaDomain" => %{
        "value" => supafana_domain
      }
    }

    {:ok, access_token} = get_graph_access_token()

    path = deployment_path(project_ref)

    r =
      client_with_retry(access_token)
      |> Tesla.put(path, %{
        "properties" => %{
          "templateLink" => %{
            "uri" => template_file_url,
            "queryString" => template_file_query_string
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
        {:ok, _} = get_graph_access_token(:renew)
        create_deployment(project_ref, service_role_key)
    end
  end

  defp deployment_path(project_ref) do
    subscription_id = Supafana.env(:azure_subscription_id)
    resource_group = Supafana.env(:azure_resource_group)
    deployment_name = "grafana-deployment-#{project_ref}"

    "/subscriptions/#{subscription_id}/resourcegroups/#{resource_group}/providers/Microsoft.Resources/deployments/#{deployment_name}?api-version=2021-04-01"
  end

  defp client_jwt() do
    url = "https://login.microsoftonline.com"

    base_url = {Tesla.Middleware.BaseUrl, url}
    form = Tesla.Middleware.FormUrlencoded
    json = Tesla.Middleware.JSON
    query = Tesla.Middleware.Query

    retry =
      {Tesla.Middleware.Retry,
       [
         delay: 1000,
         max_retries: 10,
         max_delay: 4_000,
         should_retry: fn
           {:ok, %{status: status}} when status in [400, 429, 500] -> true
           {:ok, _} -> false
           {:error, :timeout} -> true
           {:error, _} -> true
         end
       ]}

    headers =
      {Tesla.Middleware.Headers,
       [
         {
           "content-type",
           "application/json"
         },
         {
           "accept",
           "*/*"
         }
       ]}

    middleware = [base_url, form, json, query, headers, retry]

    Tesla.client(middleware)
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
