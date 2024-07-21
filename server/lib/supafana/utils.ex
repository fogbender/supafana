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
end
