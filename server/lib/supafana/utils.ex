defmodule Supafana.Utils do
  @doc """
  Returns existing atom if it exists, otherwise returns the value as is.
  """
  def maybe_atom(value) when is_binary(value) do
    try do
      String.to_existing_atom(value)
    rescue
      ArgumentError ->
        value
    end
  end

  def to_unix(%DateTime{} = t), do: t |> DateTime.to_unix(:millisecond)
  def from_unix(ms) when is_integer(ms), do: ms |> DateTime.from_unix!(:millisecond)
  def now(), do: DateTime.utc_now() |> to_unix()
  def till(ms), do: now() + ms
end
