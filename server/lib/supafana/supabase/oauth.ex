defmodule Supafana.Supabase.OAuth do
  require Logger

  def token(refresh_token) do
    r =
      client()
      |> Tesla.post("/v1/oauth/token", %{
        "grant_type" => "refresh_token",
        "refresh_token" => refresh_token
      })

    case r do
      {:ok, %Tesla.Env{status: 201, body: body}} ->
        {:ok, body}

      _ ->
        r
    end
  end

  def tokens(code, redirect_uri, code_verifier) do
    r =
      client()
      |> Tesla.post("/v1/oauth/token", %{
        "grant_type" => "authorization_code",
        "code" => code,
        "redirect_uri" => redirect_uri,
        "code_verifier" => code_verifier
      })

    case r do
      {:ok, %Tesla.Env{status: 201, body: body}} ->
        {:ok, body}

      _ ->
        r
    end
  end

  def client do
    url = "https://api.supabase.com"
    base_url = {Tesla.Middleware.BaseUrl, url}
    form = Tesla.Middleware.FormUrlencoded
    json = Tesla.Middleware.JSON
    query = Tesla.Middleware.Query

    supabase_client_id = Supafana.env(:supabase_client_id)
    supabase_client_secret = Supafana.env(:supabase_client_secret)
    authorization = Base.encode64("#{supabase_client_id}:#{supabase_client_secret}")

    headers =
      {Tesla.Middleware.Headers,
       [
         {
           "authorization",
           "Basic #{authorization}"
         }
       ]}

    middleware = [base_url, form, json, query, headers]

    Tesla.client(middleware)
  end
end
