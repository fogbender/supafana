defmodule Supafana.Cowboy do
  require Logger
  use Plug.Router, origin: "*"

  if Mix.env() == :dev do
    use Plug.Debugger, otp_app: :supafana
  end

  use Plug.ErrorHandler

  plug(Plug.Logger)
  plug(Supafana.CORS)
  plug(:match)
  plug(:dispatch)

  forward("/auth", to: Supafana.Web.AuthRouter)
  forward("/", to: Supafana.Web.Router)

  # match _ do
  #  send_resp(conn, 404, "Nothing here... yet")
  # end

  def handle_errors(conn, %{kind: kind, reason: reason, stack: stack}) do
    send_resp(
      conn,
      conn.status,
      Jason.encode!(%{"error" => kind, "reason" => reason, "stack" => stack})
    )
  end
end
