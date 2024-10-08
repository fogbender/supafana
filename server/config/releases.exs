# This file is also used as runtime dynamic configuration file for release
# So it should follow next restrictions from https://hexdocs.pm/mix/Mix.Tasks.Release.html#module-runtime-configuration:
# It MUST import Config at the top instead of the deprecated use Mix.Config
# It MUST NOT import any other configuration file via import_config
# It MUST NOT access Mix in any way, as Mix is a build tool and it not available inside releases

import Config

config :supafana,
  supabase_client_id: System.get_env("SUPABASE_CLIENT_ID"),
  supabase_client_secret: System.get_env("SUPABASE_CLIENT_SECRET"),
  secret_key_base: System.get_env("SUPAFANA_SECRET_KEY_BASE")

config :supafana,
  supafana_api_url: System.get_env("SUPAFANA_API_URL"),
  supafana_storefront_url: System.get_env("SUPAFANA_STOREFONT_URL")

config :supafana,
  loops_api_key: System.get_env("LOOPS_API_KEY")

config :supafana,
  fogbender_secret: System.get_env("FOGBENDER_SECRET"),
  fogbender_widget_id: System.get_env("FOGBENDER_WIDGET_ID")

config :supafana,
  stripe_public_key: System.get_env("STRIPE_PUBLIC_KEY"),
  stripe_secret_key: System.get_env("STRIPE_SECRET_KEY"),
  stripe_price_id: System.get_env("STRIPE_PRICE_ID")

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
