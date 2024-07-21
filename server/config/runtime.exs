import Config

# Web
config :supafana,
  supafana_ip:
    (System.get_env("SUPAFANA_IP") || "0.0.0.0")
    |> String.split(".")
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple(),
  supafana_port:
    (System.get_env("SUPAFANA_PORT") || "9080")
    |> String.to_integer()

# Database
config :supafana, Supafana.Repo,
  database: System.get_env("PG_DB"),
  username: System.get_env("PG_USER"),
  password: System.get_env("PG_PASS"),
  hostname: System.get_env("PG_HOST"),
  port: System.get_env("PG_PORT"),
  pool_size: (System.get_env("PG_POOL_SIZE") || "10") |> String.to_integer(),
  migration_timestamps: [type: :utc_datetime_usec],
  start_apps_before_migration: [:snowflake]

config :supafana,
  supabase_client_id: System.get_env("SUPABASE_CLIENT_ID"),
  supabase_client_secret: System.get_env("SUPABASE_CLIENT_SECRET"),
  secret_key_base: System.get_env("SUPAFANA_SECRET_KEY_BASE")

config :supafana,
  supafana_domain: System.get_env("SUPAFANA_DOMAIN"),
  supafana_api_url: System.get_env("SUPAFANA_API_URL"),
  supafana_storefront_url: System.get_env("SUPAFANA_STOREFRONT_URL")

config :supafana,
  loops_api_key: System.get_env("LOOPS_API_KEY")

config :supafana,
  fogbender_secret: System.get_env("FOGBENDER_SECRET"),
  fogbender_widget_id: System.get_env("FOGBENDER_WIDGET_ID")

config :supafana,
  stripe_public_key: System.get_env("STRIPE_PUBLIC_KEY"),
  stripe_secret_key: System.get_env("STRIPE_SECRET_KEY"),
  stripe_price_id: System.get_env("STRIPE_PRICE_ID")

config :supafana,
  azure_client_id: System.get_env("SUPAFANA_AZURE_CLIENT_ID"),
  azure_client_secret: System.get_env("SUPAFANA_AZURE_CLIENT_SECRET"),
  azure_tenant_id: System.get_env("SUPAFANA_AZURE_TENANT_ID"),
  azure_resource_group: System.get_env("SUPAFANA_AZURE_RESOURCE_GROUP"),
  azure_subscription_id: System.get_env("SUPAFANA_AZURE_SUBSCRIPTION_ID")

config :logger, :console,
  level: (System.get_env("SUPAFANA_LOG_LEVEL") || "debug") |> String.to_atom(),
  format: "\n$time [$level] $message $metadata\n",
  metadata: [:file, :line, :mfa, :pid]

config :snowflake,
  # values are 0 thru 1023 nodes
  machine_id: 1,
  # 2020.01.01, don't change!
  epoch: 1_577_836_800_000

config :tesla, :adapter, Tesla.Adapter.Hackney

# Disable timezone updates
config :tzdata, :autoupdate, :disabled

# Test mode settings
if config_env() == :test do
  config :supafana, Supafana.Repo,
    database: System.get_env("PG_DB") <> "_test",
    pool: Ecto.Adapters.SQL.Sandbox
end
