defmodule SortedKV do
  defstruct [:kv]

  def new(kv \\ []), do: %__MODULE__{kv: kv}

  defimpl Jason.Encoder do
    def encode(%{kv: kv}, opts) do
      kv
      |> Enum.sort()
      |> Jason.Encode.keyword(opts)
    end
  end
end

defmodule Mix.Tasks.MixToJson do
  use Mix.Task
  @task_timeout 60000

  @shortdoc "Converts current mix.lock to deps.json for nix"
  def run(_) do
    # calling our Hello.say() function from earlier
    json =
      Mix.Dep.Lock.read()
      |> Task.async_stream(
        fn {name, opts} ->
          {name, nix_opts(name, opts)}
        end,
        timeout: @task_timeout
      )
      |> Enum.map(fn {:ok, v} -> v end)
      |> SortedKV.new()
      |> Jason.encode!(pretty: true)

    File.write("./deps.json", json)
  end

  # {:hex, :connection, "1.0.4", "a1cae72211f0eef17705aaededacac3eb30e6625b04a6117c1b2db6ace7d5976", [:mix], [], "hexpm"},
  defp nix_opts(name, {:hex, pkg, version, _hash, builders, deps, _repo}) do
    SortedKV.new(
      name: name,
      fetcher: "hex",
      pkg: pkg,
      version: version,
      builder: nix_builder(builders),
      deps: nix_deps(deps),
      sha256: nix_hex_sha(name, pkg, version)
    )
  end

  # hex > 0.20.5 {:hex, :certifi, "2.5.2", "b7cfeae9d2ed395695dd8201c57a2d019c0c43ecaf8b8bcb9320b40d6662f340", [:rebar3], [{:parse_trans, "~>3.3", [hex: :parse_trans, repo: "hexpm", optional: false]}], "hexpm", "3b3b5f36493004ac3455966991eaf6e768ce9884693d9968055aeeeb1e575040"},
  defp nix_opts(name, {:hex, pkg, version, _hash, builders, deps, _repo, _hash2}) do
    SortedKV.new(
      name: name,
      fetcher: "hex",
      pkg: pkg,
      version: version,
      builder: nix_builder(builders),
      deps: nix_deps(deps),
      sha256: nix_hex_sha(name, pkg, version)
    )
  end

  # "exsync": {:git, "https://github.com/mkurkov/exsync.git", "d4a2359e90e116426f1a90939f06f7d850a0b161", [branch: "master"]}
  defp nix_opts(name, {:git, url, rev, _tag}) do
    sha = nix_git_sha(name, url, rev)

    SortedKV.new(
      name: name,
      fetcher: "git",
      url: url,
      rev: rev,
      builder: "mix",
      deps: %{},
      sha256: sha,
      version: "git"
    )
  end

  defp nix_opts(_, _) do
    %{}
  end

  defp nix_builder(builders) do
    cond do
      :mix in builders -> "mix"
      true -> "rebar3"
    end
  end

  # [{:decimal, "~> 1.6", [hex: :decimal, repo: "hexpm", optional: false]}]
  defp nix_deps(deps) do
    deps
    |> Enum.map(fn {name, _version, opts} ->
      {name, opts[:optional]}
    end)
    |> SortedKV.new()
  end

  defp nix_hex_sha(name, pkg, version) do
    sha = run_cmd("nix-universal-prefetch fetchHex --pkg #{pkg} --version #{version}")
    log("HEX", name, sha)
    sha
  end

  defp nix_git_sha(name, url, rev) do
    sha = run_cmd("nix-universal-prefetch fetchgit --url #{url} --rev #{rev} --leaveDotGit true")
    log("GIT", name, sha)
    sha
  end

  defp run_cmd(cmd) do
    cmd
    |> String.to_charlist()
    |> :os.cmd()
    |> List.to_string()
    |> String.trim()
  end

  defp log(type, name, sha) do
    title = String.pad_trailing("#{name}", 30, ".")
    IO.puts("#{type} #{title}#{sha}")
  end
end
