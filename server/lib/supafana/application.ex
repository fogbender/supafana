defmodule Supafana.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  # deploy bump 1
  @moduledoc false

  use Application

  def start(_type, _args) do
    children =
      [
        # Starts a worker by calling: Supafana.Worker.start_link(arg)
        # {Supafana.Worker, arg}
        Supafana.Repo,
        Registry.child_spec(keys: :unique, name: Registry.Supafana),
        {Task.Supervisor, name: Supafana.TaskSupervisor},
        Supafana.Web.Task.child_spec(),
        cowboy(),
        {Finch,
         name: AzureFinch,
         pools: %{
           :default => [size: 32, count: 8]
         }},
        Supafana.Scheduler
      ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Supafana.Supervisor]
    res = Supervisor.start_link(children, opts)

    :azure_token_cache = :ets.new(:azure_token_cache, [:public, :named_table])

    IO.puts("Supafana service started with configuration:")
    IO.puts(Supafana.info())
    res
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
