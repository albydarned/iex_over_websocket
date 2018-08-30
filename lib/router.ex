defmodule RemoteShell.Router do
  use Plug.Router

  plug Plug.Static, from: {:remote_shell, Path.join("priv", "static")}, at: "/"
  plug Plug.Logger, otp_app: :remote_shell
  plug :match
  plug :dispatch

  match _ do
    send_resp(conn, 404, "oops")
  end
end
