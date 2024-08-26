defmodule Support.RepoCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Supafana.{Repo, Data}

      import Ecto
      import Ecto.Query
      import Support.RepoCase
      import Support.RepoUtils
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Supafana.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Supafana.Repo, {:shared, self()})
    end

    :ok
  end
end
