defmodule Supafana do
  @moduledoc """
  Documentation for Supafana
  """

  @doc """
  Hello world.

  """
  def env(key) do
    Application.get_env(:supafana, key)
  end

  def info() do
    [
      current_directory: File.cwd!(),
      supafana_ip: env(:supafana_ip),
      supafana_port: env(:supafana_port)
    ]
    |> info_pp()
  end

  defp info_pp(info) do
    for {n, v} <- info do
      [inspect(n), "\t ", inspect(v)]
    end
    |> Enum.join("\n")
  end
end
