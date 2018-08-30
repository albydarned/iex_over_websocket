defmodule RemoteShell.Socket do
  @behaviour :cowboy_websocket

  def iex_init(_socket, _state) do
    :ok
  end

  def gets(socket, _, message) do
    send socket, {:gets, self(), message}
    receive do
      {:results, data} -> data
    end
  end

  def puts(socket, device \\ :stdio, message)

  def puts(socket, _, message) do
    send socket, {:puts, to_string(message)}
  end

  def init(req, state) do
    {:cowboy_websocket, req, state}
  end

  def websocket_init(state) do
    socket = self()
    iex_pid = spawn_link fn() ->
      Remote.IEx.Server.start([gets: &gets(socket, &1, &2), puts: &puts(socket, &1, &2)], {__MODULE__, :iex_init, [socket, state]})
    end
    {:ok, %{iex_pid: iex_pid, gets_pid: nil}}
  end

  def websocket_handle({:text, data}, state) do
    case Jason.decode(data) do
      {:ok, data} -> websocket_handle({:json, data}, state)
      _ -> {:ok, state}
    end
  end

  def websocket_handle({:json, %{"type" => "gets", "data" => results}}, %{gets_pid: pid} = state) when is_pid(pid) do
    send pid, {:results, results}
    {:ok, %{state | gets_pid: nil}}
  end

  def websocket_info({:gets, pid, message}, state) do
    {:reply, {:text, Jason.encode!(%{type: "gets", data: message})}, %{state | gets_pid: pid}}
  end

  def websocket_info({:puts, message}, state) do
    {:reply, {:text, Jason.encode!(%{type: "puts", data: message})}, state}
  end
end
