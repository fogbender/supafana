defmodule Supafana.MixProject do
  use Mix.Project

  def project do
    [
      app: :supafana,
      version:
        with v <- String.trim(File.read!("VERSION")),
             {:ok, _} <- Version.parse(v) do
          v
        else
          _ ->
            "0.0.0-epic-fail"
        end,
      elixir: "~> 1.16.3",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [supafana: release()],
      elixirc_options: [warnings_as_errors: true],
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  def release do
    [
      include_erts: false,
      include_executables_for: [:unix]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Supafana.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:briefly, "~> 0.3"},
      {:configparser_ex, "~> 4.0"},
      {:corsica, "~> 1.0"},
      {:ecto_sql, "~> 3.11"},
      {:postgrex, "~> 0.18.0"},
      {:hackney, "~> 1.20.1"},
      {:finch, "~> 0.18"},
      {:cyanide, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:joken, "~> 2.0"},
      {:joken_jwks, "~> 1.1.0"},
      {:plug_cowboy, "~> 2.4"},
      {:recon, "~> 2.5"},
      {:snowflake, "~> 1.0"},
      {:tesla, "~> 1.4.0"},
      {:syn, "~> 2.1"},
      {:quantum, "~> 3.4"},
      {:timex, "~> 3.7"},
      {:bamboo, "~> 2.0"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
