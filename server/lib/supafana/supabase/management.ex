defmodule Supafana.Supabase.Management do
  require Logger

  def organization_members(token, slug) do
    Logger.info("Calling members with token #{token} for slug #{slug}")

    path = "/v1/organizations/#{slug}/members"

    r =
      client(token)
      |> Tesla.get(path)

    case r do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}
    end
  end

  def project_api_keys(token, project_ref) do
    path = "/v1/projects/#{project_ref}/api-keys"
    client(token) |> Tesla.get(path)
  end

  def project_health(token, project_ref) do
    path = "/v1/projects/#{project_ref}/health"

    client(token)
    |> Tesla.get(path,
      query: [
        services: ["db"]
      ]
    )
  end

  def projects(token) do
    path = "/v1/projects"

    r =
      client(token)
      |> Tesla.get(path)

    case r do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}
    end
  end

  def organizations(token) do
    path = "/v1/organizations"
    client(token) |> Tesla.get(path)
  end

  def client(token) do
    url = "https://api.supabase.com"
    base_url = {Tesla.Middleware.BaseUrl, url}
    json = Tesla.Middleware.JSON
    query = Tesla.Middleware.Query

    headers =
      {Tesla.Middleware.Headers,
       [
         {
           "authorization",
           "Bearer #{token}"
         }
       ]}

    middleware = [base_url, json, query, headers]

    Tesla.client(middleware)
  end
end
