defmodule Support.RepoUtils do
  alias Supafana.{Repo, Data}

  def id(), do: Ecto.UUID.generate()

  def org() do
    id = id()

    Data.Org.new(
      id: id,
      supabase_id: "supabase-#{id}",
      name: "org-#{id}"
    )
    |> Repo.insert!()
  end
end
