Code.put_compiler_option(:warnings_as_errors, true)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Supafana.Repo, :manual)
