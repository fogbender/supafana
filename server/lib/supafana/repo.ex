defmodule Supafana.Repo do
  use Ecto.Repo,
    otp_app: :supafana,
    adapter: Ecto.Adapters.Postgres

  require Logger

  def configure(config) do
    Logger.info("Running repo configure")

    case Supafana.env(Supafana.Repo)[:password] do
      "AZURE_IDENTITY" ->
        Logger.debug("Loading token...")
        init_with_instance_identity(config)

      _ ->
        Logger.debug("No configuration needed")
        config
    end
  end

  defp init_with_instance_identity(config) do
    {:ok, access_token} = Supafana.Azure.Auth.db_access_token()
    Keyword.put(config, :password, access_token)
  end
end
