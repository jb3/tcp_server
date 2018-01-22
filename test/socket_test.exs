defmodule SocketTest do
  use ExUnit.Case
  doctest Socket

  test "greets the world" do
    assert Socket.hello() == :world
  end
end
