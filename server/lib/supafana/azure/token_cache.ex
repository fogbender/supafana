defmodule Supafana.Azure.TokenCache do
  use GenServer
  require Logger

  alias Supafana.{Utils}

  @table_name :azure_token_cache

  def init(arg) do
    :ets.new(@table_name, [
      :set,
      :public,
      :named_table,
      {:read_concurrency, true},
      {:write_concurrency, true}
    ])

    {:ok, arg}
  end

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def get(key) do
    now = Utils.now()

    case :ets.lookup(@table_name, key) do
      [] ->
        Logger.debug("Cache: key not found key: #{inspect(key)}")
        nil

      [{_key, {_token, exp}}] when now >= exp ->
        Logger.debug("Cache: key expired key: #{inspect(key)}, exp: #{inspect(exp)}")
        nil

      [{_key, {token, _exp}}] ->
        token
    end
  end

  def put(key, token, exp) do
    :ets.insert(@table_name, {key, {token, exp}})
  end
end
