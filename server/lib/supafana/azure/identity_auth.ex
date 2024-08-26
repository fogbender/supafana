defmodule Supafana.Azure.IdentityAuth do
  @api_version "2018-02-01"

  def get_access_token(resource) do
    path = "/metadata/identity/oauth2/token"

    r =
      client()
      |> Tesla.get(path,
        query: [
          resource: resource,
          "api-version": @api_version
        ]
      )

    case r do
      {:ok,
       %Tesla.Env{
         status: 200,
         body: %{"access_token" => access_token, "expires_on" => expires_on}
       }} ->
        {:ok, access_token, String.to_integer(expires_on) * 1000}
    end
  end

  defp client() do
    url = "http://169.254.169.254"
    base_url = {Tesla.Middleware.BaseUrl, url}
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
         {"Metadata", "true"},
         {"accept", "*/*"}
       ]}

    middleware = [base_url, json, query, headers, retry]
    Tesla.client(middleware)
  end
end
