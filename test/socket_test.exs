defmodule TCPServerTest do
  use ExUnit.Case
  doctest TCPServer

  test "greets the world" do
    assert TCPServer.hello() == :world
  end
end
