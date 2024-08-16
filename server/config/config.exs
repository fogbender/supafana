import Config

config :supafana, Supafana.Repo,
  database: "supafana_repo",
  username: "user",
  password: "pass",
  hostname: "localhost",
  configure: {Supafana.Repo, :configure, []}

# Repo
config :supafana,
  ecto_repos: [Supafana.Repo]
