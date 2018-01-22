require Logger
defmodule Socket.Agent do
    use Agent
    
    def start_link(_) do
        Logger.info "Agent now ready"
        Agent.start_link(fn -> Map.new end, name: __MODULE__)
    end

    def start_request(port, path, method) do
        Agent.get_and_update(__MODULE__, fn x ->
            x = Map.put x, port, %{}
            r = Map.update(x, port, %{}, fn e ->
                Map.put(e, :path, path)
                    |> Map.put(:method, method)
            end)
            {r, r}
        end)
    end

    def add_header(port, header, value) do
        Agent.get_and_update(__MODULE__, fn x ->
            t = Map.update(x, port, %{}, fn e ->
                Map.put(e, header, value)
            end)
            {t, t}
        end)
    end

    def delete_request(port) do
        Agent.get_and_update(__MODULE__, fn x ->
            y = Map.delete(x, port)
            {y, y}
        end)
    end

    def fetch_request(port) do
        Agent.get(__MODULE__, fn x ->
            Map.get(x, port)
        end)
    end

    def fetch_all() do
        Agent.get(__MODULE__, fn x ->
            x
        end)
    end
end