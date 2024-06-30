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
