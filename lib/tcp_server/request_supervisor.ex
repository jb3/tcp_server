require Logger

defmodule TCPServer.RequestSupervisor do
  use DynamicSupervisor

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_child(state) do
    spec = {TCPServer.RequestServer, state}

    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @impl true
  def init(_arg) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      extra_arguments: [],
      restart: :temporary
    )
  end
end
