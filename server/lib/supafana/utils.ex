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
  def from_unix(us) when is_integer(us), do: us |> DateTime.from_unix!(:millisecond)
end
