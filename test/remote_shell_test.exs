defmodule RemoteShellTest do
  use ExUnit.Case
  doctest RemoteShell

  test "greets the world" do
    assert RemoteShell.hello() == :world
  end
end
