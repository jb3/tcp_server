require Logger
defmodule Socket.RequestSupervisor do
    use Supervisor

    alias Socket.RequestServer

    def start_link() do
        spec = worker(RequestServer, [], [restart: :temporary])
        options = [
            strategy: :simple_one_for_one,
            name: __MODULE__,
            restart: :temporary
        ]

        Supervisor.start_link([spec], options)
    end

    def start_child(state) do
        __MODULE__
        |> Supervisor.start_child(state)
    end
end