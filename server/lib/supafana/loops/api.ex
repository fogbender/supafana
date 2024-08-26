defmodule Supafana.Loops.Api do
  def send_tx(tx_id, email, data_vars) do
    path = "/api/v1/transactional"

    client()
    |> Tesla.post(path, %{
      "transactionalId" => tx_id,
      "email" => email,
      "dataVariables" => data_vars
    })
  end

  def client() do
    api_key = Supafana.env(:loops_api_key)
    url = "https://app.loops.so"
    base_url = {Tesla.Middleware.BaseUrl, url}
    json = Tesla.Middleware.JSON
    query = Tesla.Middleware.Query

    headers =
      {Tesla.Middleware.Headers,
       [
         {
           "authorization",
           "Bearer #{api_key}"
         }
       ]}

    middleware = [base_url, json, query, headers]

    Tesla.client(middleware)
  end
end
