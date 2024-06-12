defmodule Mix.Tasks.Version do
  use Mix.Task

  @moduledoc """
  Utils for versioning

  Version has format Y.M.C, where
  Y - year
  M - month (without leading zero)
  C - release counter in current month

  ## Usage

  `mix version bump` - increment counter if revision is in current month or update version to Y.M.0
  and save it to VERSION file
  """

  @version_file "./VERSION"

  def run(["bump"]) do
    file = @version_file |> File.read!()

    # in case of merge conflict there is going to be multiple versions in one file, let's take bigger one
    lines = String.split(file, "\n")
    versions = Enum.filter(lines, &(Version.parse(&1) !== :error))
    versions = Enum.sort(versions, &(Version.compare(&1, &2) != :lt))
    [vsn | _] = versions

    vsn =
      vsn
      |> version()
      |> update_version(Date.utc_today())
      |> format()

    File.write(@version_file, "#{vsn}\n")
    IO.puts(vsn)
  end

  defp update_version([y, m, c], %Date{year: y, month: m}), do: [y, m, c + 1]
  defp update_version([y, _m, _c], %Date{year: y, month: m1}), do: [y, m1, 0]
  defp update_version([_y, _m, _c], %Date{year: y1, month: m1}), do: [y1, m1, 0]

  defp format([y, m, c]), do: "#{y}.#{m}.#{c}"

  defp version(version_string) do
    version_string
    |> String.split([".", "-"])
    |> Enum.take(3)
    |> Enum.map(&String.to_integer/1)
  end
end
