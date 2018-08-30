defmodule RemoteShell.Application do
  use Application
  alias RemoteShell.{Router, Socket}

  def start(_, args) do
    Supervisor.start_link(__MODULE__, args, [name: __MODULE__])
  end

  def init([]) do
    children = [
      {Plug.Adapters.Cowboy2, scheme: :http, plug: Router, options: [port: 4000, dispatch: dispatch()]}
    ]
    Supervisor.init(children, [strategy: :one_for_one])
  end

  def dispatch do
    [
      {:_, [
        {"/ws", Socket, []},
        {:_, Plug.Adapters.Cowboy2.Handler, {Router, []}}
      ]}
    ]
  end
end
