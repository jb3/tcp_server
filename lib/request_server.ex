require Logger
defmodule Socket.RequestServer do
    use GenServer

    def start_link(client) do
        GenServer.start_link __MODULE__, client
    end

    def init(client) do
        Logger.info "Starting GenServer to handle request"
          
        {:ok, client}
    end


    def handle_info({:http, socket, {:http_request, method, {:abs_path, path}, _version}}, state) do
        Socket.Agent.start_request(socket, path, method)
        Logger.debug "Received http start"
        {:noreply, state}
    end

    def handle_info({:http, socket, {:http_header, _number, header_name, :undefined, content}}, state) do
        Socket.Agent.add_header(socket, header_name, content)
        Logger.debug "Received header #{header_name}"
        {:noreply, state}
    end

    def handle_info({:http, socket, :http_eoh}, state) do
        Logger.debug "Recieved END OF HEADERS"
        Socket.Server.handle_request(Socket.Agent.fetch_request(socket), socket, self())
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
