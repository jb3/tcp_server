require Logger
defmodule Socket.Server do
    use GenServer

    def start_link() do
        Logger.info "Starting connection GenServer"
        GenServer.start_link(__MODULE__, [{0,0,0,0}, 1337])
    end

    def init([ip, port]) do
        {:ok, listen_socket} = :gen_tcp.listen(port,
                          [:binary, packet: :http, active: false, reuseaddr: true, ip: ip])
        send self(), {:loop, listen_socket}
        {:ok, %{ip: {0,0,0,0}, port: 1337, socket: listen_socket}}
    end

    def handle_info({:loop, socket}, state) do
        {:ok, client} = :gen_tcp.accept(socket)

        {:ok, pid} = Socket.RequestSupervisor.start_child([client])
        IO.puts "Handover return: " <> Kernel.inspect(:gen_tcp.controlling_process(client, pid))
        options = [
            active: true,
            packet: :http
          ]
        IO.puts "setopts return: " <> Kernel.inspect(:inet.setopts(client, options))

        send self(), {:loop, socket}
        {:noreply, state}
    end


    def send_response(status, body, socket, request, headers \\ %{}) do
        h = prepare_headers(request, headers)

        response = "HTTP/1.1 " <> status <> "\r\n"
        response = response <> h
        response = response <> "\r\n\r\n" <> body

        write_line(response, socket)
        :gen_tcp.close(socket)
    end

    def handle_request(request, socket) do
        Logger.debug request.path
        case request.path do
            '/' -> send_response("200 OK", "<h1>Hello webserver?</h1><a href='/test'>Hello?</a>", socket, request)
            '/test' -> send_response("200 OK", "<h1>Hello me again xd</h1>", socket, request)
            '/user-agent' -> send_response("200 OK", "<p>You have a user agent of #{Map.get(request.headers, :"User-Agent")}</p>", socket, request)
            '/redirect' -> send_response("200 OK", "<p>Hello redirect?</p>", socket, request, %{"Location": "https://seph.club/"})
            _ -> send_response("404 PAGE NOT FOUND", "", socket, request)
        end
    end

    defp prepare_headers(request, user_headers) do
        headers = %{
            "Location": Map.get(request, :path),
            "Server": "Seph serber",
            "Date": DateTime.utc_now() |> DateTime.to_iso8601(),
            "Connection": "close",
            "Content-Type": "text/html",
            "ETag": :crypto.hash(:sha256, :crypto.strong_rand_bytes(10)) |> Base.encode16 |> String.downcase
        }

        headers = Map.merge(headers, user_headers)
        IO.inspect headers
        Enum.map(headers, fn x -> "#{elem(x, 0)}: #{elem(x, 1)}" end) |> Enum.join("\r\n")
    end

    def write_line(line, socket) do
        :gen_tcp.send(socket, line)
    end

    def read_line(socket) do
        :gen_tcp.recv(socket, 0)
    end
end
