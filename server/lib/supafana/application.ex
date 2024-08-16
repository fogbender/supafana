defmodule Supafana.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  # deploy bump 1
  @moduledoc false

  use Application

  def start(_type, _args) do
    children =
      case Supafana.env(:minimal) do
        true ->
          children_minimal()

        _ ->
          children_minimal() ++ children_full()
      end

    opts = [strategy: :one_for_one, name: Supafana.Supervisor]
    res = Supervisor.start_link(children, opts)

    IO.puts("Supafana service started with configuration:")
    IO.puts(Supafana.info())
    res
  end

  # minimal setup for migrations
  defp children_minimal() do
    [
      Supafana.Azure.TokenCache,
      {Finch,
       name: AzureFinch,
       pools: %{
         :default => [size: 32, count: 8]
       }}
    ]
  end

  defp children_full() do
    [
      Supafana.Repo,
      Registry.child_spec(keys: :unique, name: Registry.Supafana),
      {Task.Supervisor, name: Supafana.TaskSupervisor},
      Supafana.Web.Task.child_spec(),
      cowboy(),
      Supafana.Scheduler
    ]
  end

  defp cowboy do
    {Plug.Cowboy,
     scheme: :http,
     plug: Supafana.Cowboy,
     options: [
       dispatch: dispatch(),
       port: Supafana.env(:supafana_port),
       ip: Supafana.env(:supafana_ip)
     ]}
  end

  defp dispatch do
    [
      {:_,
       [
         {:_, Plug.Cowboy.Handler, {Supafana.Cowboy, []}}
       ]}
    ]
  end
end
