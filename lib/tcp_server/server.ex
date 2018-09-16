require Logger

defmodule TCPServer.Server do
  use GenServer

  def start_link() do
    Logger.info("Starting connection GenServer")
    GenServer.start_link(__MODULE__, [{0, 0, 0, 0}, 1337], name: __MODULE__)
  end

  def init([ip, port]) do
    {:ok, listen_socket} =
      :gen_tcp.listen(
        port,
        [:binary, packet: :http, active: false, reuseaddr: true, ip: ip]
      )

    send(self(), {:loop, listen_socket})
    {:ok, %{ip: {0, 0, 0, 0}, port: 1337, socket: listen_socket}}
  end

  def handle_info({:loop, socket}, state) do
    {:ok, client} = :gen_tcp.accept(socket)

    {:ok, pid} = TCPServer.RequestSupervisor.start_child([client])
    :gen_tcp.controlling_process(client, pid)

    options = [
      active: true,
      packet: :http
    ]

    :inet.setopts(client, options)

    send(self(), {:loop, socket})

    {:noreply, state}
  end

  def send_response(status, body, socket, request, headers \\ %{}) do
    headers = Map.put headers, :ETag, "\"" <> (:crypto.hash(:md5, body) |> Base.encode16(case: :lower)) <> "\""
    h = prepare_headers(request, headers)

    response = "HTTP/1.1 " <> status <> "\r\n"
    response = response <> h
    response = response <> "\r\n\r\n" <> body

    write_line(response, socket)
    :gen_tcp.close(socket)
  end

  def handle_request(request, socket) do
    Logger.debug(request.path)

    case request.path do
      '/' ->
        send_response(
          "200 OK",
          "<h1>System working? Seems to be.</h1>",
          socket,
          request
        )
      _ ->
        send_response("404 PAGE NOT FOUND", "", socket, request)
    end
  end

  defp prepare_headers(request, user_headers) do
    headers = %{
      Location: Map.get(request, :path),
      Server: "Seph serber",
      Date: DateTime.utc_now() |> DateTime.to_iso8601(),
      Connection: "close",
      "Content-Type": "text/html",
    }

    headers = Map.merge(headers, user_headers)
    IO.inspect(headers)
    Enum.map(headers, fn x -> "#{elem(x, 0)}: #{elem(x, 1)}" end) |> Enum.join("\r\n")
  end

  def write_line(line, socket) do
    :gen_tcp.send(socket, line)
  end

  def read_line(socket) do
    :gen_tcp.recv(socket, 0)
  end
end
