require Logger
defmodule Socket.RequestServer do
    use GenServer

    def start_link(client) do
      GenServer.start_link __MODULE__, client
    end

    def init(client) do
      Logger.info "Starting GenServer to handle request"

      state_data = %{
        client: client,
        headers: %{},
        method: nil,
        path: nil,
        version: nil
      }

      {:ok, state_data}
    end


    def handle_info({:http, _socket, {:http_request, method, {:abs_path, path}, http_version}}, state) do
      state = state
        |> Map.put(:method, method)
        |> Map.put(:path, path)
        |> Map.put(:version, http_version)
      Logger.debug "Received http start"
      {:noreply, state}
    end

    def handle_info({:http, _socket, {:http_header, _number, header_name, :undefined, content}}, state) do
      new_headers = Map.put(state.headers, header_name, content)
      state = Map.put(state, :headers, new_headers)
      Logger.debug "Received header #{header_name}"
      {:noreply, state}
    end

    def handle_info({:http, socket, :http_eoh}, state) do
      Logger.debug "Recieved END OF HEADERS"
      Socket.Server.handle_request(state, socket)
      {:noreply, state}
    end

    def handle_info({:tcp_closed, _socket}, state) do
      Logger.debug "TCP Connection closed"
      {:stop, :normal, state}
    end

    def handle_info(data, state) do
      Logger.debug "Unhandled data"
      Logger.debug Kernel.inspect(data)
      {:noreply, state}
    end
end
