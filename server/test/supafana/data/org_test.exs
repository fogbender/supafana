defmodule Supafana.Data.OrgTest do
  use Support.RepoCase
  alias Supafana.{Data, Repo}

  describe "Org" do
    test "create" do
      org =
        Data.Org.new(supabase_id: "abcdef", name: "Org 1")
        |> Repo.insert!()

      assert %Data.Org{} = org
    end

    test "create with repo utils" do
      assert %Data.Org{} = org()
    end
  end
end
