defmodule Supafana.CORS do
  require Logger

  use Corsica.Router,
    # if we set `origins: "*"` while it works it has almost all vulnerabilities explained in the article https://portswigger.net/research/exploiting-cors-misconfigurations-for-bitcoins-and-bounties so we are doing more thorough white listing instead
    origins: [{__MODULE__, :check_origin, []}],
    allow_credentials: true,
    allow_headers: ["content-type", "authorization"],
    max_age: 600

  resource("/*")

  # XXX probably needs connection as first arg?
  def check_origin(_conn, origin) do
    uri = URI.parse(origin)
    uri = %{uri | authority: nil}

    # resetting `authority` and checking that it produces the same url bans origins that are like `https://localhost sdfvksnfnv`

    URI.to_string(uri) === origin and check_origin_with_fixed_authority(uri)
  end

  defp check_origin_with_fixed_authority(uri) do
    %URI{
      authority: nil,
      fragment: nil,
      host: host,
      path: nil,
      port: port,
      query: nil,
      scheme: scheme,
      userinfo: nil
    } = uri

    case {scheme, host, port} do
      {"http", "localhost", 5173} ->
        true

      {"https", hostname, 443} ->
        check_origin_hostname(hostname)

      _ ->
        # Logger.debug("unsupported origin", origin: URI.to_string(uri))
        false
    end
  end

  defp check_origin_hostname(hostname) do
    IO.inspect({:hostname, hostname})
    allowedHosts = [
      # prod
      {:exact, "ask.briefly.legal"},
      {:exact, "scrape-vm-prod-02.eastus2.cloudapp.azure.com"},

      # stage
      {:exact, "wonderful-pebble-0bd64a010.4.azurestaticapps.net"},
      {:exact, "scrape-vm-stage-00.eastus.cloudapp.azure.com"},

      # int
      {:exact, "gray-pond-03694bb10.4.azurestaticapps.net"},
      {:exact, "scrape-vm-int-00.eastus.cloudapp.azure.com/embeddings-api"}
    ]

    Enum.any?(allowedHosts, fn
      {:exact, allowed} ->
        hostname == allowed

      {:netlify, allowed} ->
        String.match?(hostname, ~r/^[[:alnum:]]+#{Regex.escape(allowed)}$/)
    end)
  end
end
