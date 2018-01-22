require Logger
defmodule Socket do
  use Supervisor
  use Application

  alias Socket.{Server, RequestSupervisor}

  def start(_type, _args) do

    start_link([])
  end
  
  def start_link(arg) do
    children = [
      {Socket.Agent, [name: Socket.Agent]},
      worker(Server, []),
      supervisor(Socket.RequestSupervisor, [])
    ]

    options = [
      strategy: :one_for_one,
      name: __MODULE__
    ]
    Supervisor.start_link(children, options)
  end
end
