defmodule RemoteShell.Socket do
  @behaviour :cowboy_websocket
  alias RemoteShell.Socket, as: State
  defstruct [:iex_pid, :request]

  def iex_init() do
    :ok
  end

  def init(req, state) do
    {:cowboy_websocket, req, state}
  end

  def init_iex(%State{} = state) do
    true  = :erlang.group_leader(self(),  self())
    iex_pid = spawn_link fn() ->
      IEx.Server.start [], {__MODULE__, :iex_init, []}
    end
    %State{state | iex_pid: iex_pid, request: nil}
  end

  def websocket_init(_state) do
    state = init_iex(%State{})
    {:ok, state}
  end

  def websocket_handle({:text, data}, state) do
    case Jason.decode(data) do
      {:ok, data} -> websocket_handle({:json, data}, state)
      _ -> {:ok, state}
    end
  end

  def websocket_handle({:json, _rpc}, %State{request: nil} = state) do
    {:ok, state}
  end

  def websocket_handle({:json, %{"kind" => "put_chars", "data" => "ok"}}, %State{} = state) do
    {from, reply_as, {:put_chars, _, _}} = state.request
    io_reply(from,  reply_as, :ok)
    state = %State{request: nil}
    {:ok, state}
  end


  def websocket_handle({:json, %{"kind" => "get_line", "data" => data}}, %State{} = state) do
    {from, reply_as, {:get_line, _, _}} = state.request
    io_reply(from,  reply_as, data)
    state = %State{request: nil}
    {:ok, state}
  end

  def websocket_info({:EXIT, pid,  _reason},  %State{iex_pid: pid} =  state) do
    {:stop, state}
  end

  def websocket_info({:io_request, from, reply_as, req}, %State{} = state) do
    io_request(from, reply_as, req, state)
  end

  defp io_request(from, reply_as, {:setopts, _opts}, state) do
    reply = {:error, :enotsup}
    io_reply(from, reply_as, reply)
    {:ok, state}
  end

  defp io_request(from, reply_as, :getopts, state) do
    reply = {:ok, [binary: true, encoding: :unicode]}
    io_reply(from, reply_as, reply)
    {:ok, state}
  end

  defp io_request(from, reply_as, {:get_geometry, :columns}, state) do
    reply = {:error, :enotsup}
    io_reply(from, reply_as, reply)
    {:ok, state}
  end

  defp io_request(from, reply_as, {:get_geometry, :rows}, state) do
    reply = {:error, :enotsup}
    io_reply(from, reply_as, reply)
    {:ok, state}
  end

  defp io_request(from, reply_as, req, state) do
    state = %State{state | request: {from, reply_as, req}}
    reply = json_request(from,  reply_as, req)
    {:reply, reply, state}
  end

  defp json_request(_from, _reply_as, {:put_chars, :unicode, msg}) do
    {:text, %{kind: "put_chars",  data: msg}
    |> Jason.encode!()}
  end

  defp json_request(_from, _reply_as, {:put_chars, :latin1, msg}) do
    {:text, %{kind: "put_chars",  data: msg}
    |> Jason.encode!()}
  end

  defp json_request(_from, _reply_as, {:get_line, :unicode, msg}) do
    {:text, %{kind: "get_line", data: msg}
    |> Jason.encode!()}
  end

  defp io_reply(from, reply_as, reply) do
    send(from, {:io_reply, reply_as, reply})
  end
end
