require Logger

defmodule TCPServer.RequestServer do
  use GenServer

  def start_link(client) do
    GenServer.start_link(__MODULE__, client)
  end

  def init([client]) do
    Logger.info("Starting GenServer to handle request")

    state_data = %{
      client: client,
      headers: %{},
      method: nil,
      path: nil,
      version: nil,
      exit_reason: nil
    }

    {:ok, state_data}
  end

  def terminate(_reason, state) do
    client = state.client

    error_resp = """
    HTTP/1.1 500 INTERNAL SERVER ERROR
    Server: Seph serber
    Content-Type: text/html
    Connection: close
    <!DOCTYPE html>
    <html>
      <head>
        <title>Internal Server Error</title>
      </head>
      <body>
        <h1>Error 500</h1>
        <p>There was an issue processing your request and the server was forced to terminate</p>
      </body>
    </html>
    """

    :gen_tcp.send(client, error_resp)

    :gen_tcp.close(client)
  end

  def handle_info(
        {:http, _socket, {:http_request, method, {:abs_path, path}, http_version}},
        state
      ) do
    Logger.debug("Received http start")
    {:noreply, %{state | method: method, path: path, version: http_version}}
  end

  def handle_info(
        {:http, _socket, {:http_header, _number, header_name, :undefined, content}},
        state
      ) do
    new_headers = Map.put(state.headers, header_name, content)
    Logger.debug("Received header #{header_name}")
    {:noreply, %{state | headers: new_headers}}
  end

  def handle_info({:http, socket, :http_eoh}, state) do
    Logger.debug("Recieved END OF HEADERS")
    TCPServer.Server.handle_request(state, socket)
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _socket}, state) do
    Logger.debug("TCP Connection closed")
    {:stop, :normal, state}
  end

  def handle_info({:http, _socket, {:http_error, _err}}, state) do
    Logger.debug("Corrupted HTTP message received, terminating...")
    {:stop, :normal, state}
  end
end
