defmodule Supafana.Azure.Auth do
  alias Supafana.Azure

  require Logger

  def access_token(resource, mode \\ :cached)

  def access_token(resource, :cached) do
    case Azure.TokenCache.get({:access_token, resource}) do
      nil ->
        access_token(resource, :renew)

      token ->
        {:ok, token}
    end
  end

  def access_token(resource, :renew) do
    {:ok, token, exp} = get_access_token(resource)
    Azure.TokenCache.put({:access_token, resource}, token, exp)
    Logger.debug("Azure key loaded for #{resource}")
    {:ok, token}
  end

  def db_access_token(mode \\ :cached) do
    resource = "https://ossrdbms-aad.database.windows.net"
    access_token(resource, mode)
  end

  def api_access_token(mode \\ :cached) do
    resource = "https://management.azure.com"
    access_token(resource, mode)
  end

  # Internals

  defp get_access_token(resource) do
    case Supafana.env(:azure_client_id) do
      "AZURE_IDENTITY" ->
        Azure.IdentityAuth.get_access_token(resource)

      _ ->
        Azure.ClientAuth.get_access_token(resource)
    end
  end
end
