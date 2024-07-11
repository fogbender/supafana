defmodule Supafana.Repo do
  use Ecto.Repo,
    otp_app: :supafana,
    adapter: Ecto.Adapters.Postgres
end
