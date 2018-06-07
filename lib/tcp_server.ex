defmodule TCPServer do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec
    children = [
      worker(TCPServer.Server, []),
      supervisor(TCPServer.RequestSupervisor, [])
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
