config :supafana, Supafana.Repo, database: System.get_env("PG_DB") <> "_test"
