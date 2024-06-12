defmodule Supafana.Web.Router do
  require Logger

  use Plug.Router

  plug(:match)

  plug(:fetch_query_params)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug(:dispatch)

  post "/" do
    conn |> send_resp(204, "")
  end
end
