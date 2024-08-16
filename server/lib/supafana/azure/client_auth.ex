defmodule Supafana.Azure.ClientAuth do
  alias Supafana.{Utils}

  def get_access_token(resource) do
    tenant_id = Supafana.env(:azure_tenant_id)
    client_id = Supafana.env(:azure_client_id)
    client_secret = Supafana.env(:azure_client_secret)
    path = "/#{tenant_id}/oauth2/v2.0/token"

    r =
      client()
      |> Tesla.post(path, %{
        grant_type: "client_credentials",
        client_id: client_id,
        client_secret: client_secret,
        scope: "#{resource}/.default"
      })

    case r do
      {:ok,
       %Tesla.Env{
         status: 200,
         body: %{"access_token" => access_token, "expires_in" => expires_in}
       }} ->
        {:ok, access_token, Utils.till(expires_in * 1000)}
    end
  end

  defp client() do
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
         {"content-type", "application/json"},
         {"accept", "*/*"}
       ]}

    middleware = [base_url, form, json, query, headers, retry]
    Tesla.client(middleware)
  end
end
