defmodule Supafana.Fogbender.Api do
  def tokens(organization_slug, email, user_id) do
    path = "/tokens"

    client()
    |> Tesla.post(path, %{
      "userId" => user_id,
      "email" => email,
      "userName" => email,
      "customerId" => organization_slug
    })
  end

  def client() do
    secret = Supafana.env(:fogbender_secret)
    url = "https://api.fogbender.com"
    base_url = {Tesla.Middleware.BaseUrl, url}
    json = Tesla.Middleware.JSON
    query = Tesla.Middleware.Query

    headers =
      {Tesla.Middleware.Headers,
       [
         {
           "authorization",
           "Bearer #{secret}"
         }
       ]}

    middleware = [base_url, json, query, headers]

    Tesla.client(middleware)
  end
end
