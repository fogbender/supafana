defmodule Supafana.Web.Utils do
  import Plug.Conn

  def ok_json(conn, data, should_encode \\ :encode) do
    out =
      if should_encode == :encode do
        data |> Jason.encode!(pretty: true)
      else
        data
      end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, out)
  end

  def ok_no_content(conn) do
    conn |> send_resp(204, "")
  end

  def forbid(conn, message \\ "") do
    conn |> send_resp(403, message)
  end

  def not_authorized(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, Jason.encode!(%{"error" => "not authorized"}))
    |> halt()
  end

  def ensure_own_project(access_token, project_ref) do
    case Supafana.Supabase.Management.project_api_keys(access_token, project_ref) do
      {:ok, %{status: 200, body: keys}} ->
        service_key = (keys |> Enum.find(&(&1["name"] == "service_role")))["api_key"]
        {:ok, service_key}

      _ ->
        false
    end
  end
end
