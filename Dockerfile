FROM elixir:alpine

RUN mkdir -p /opt/tcp_server

COPY mix.exs /opt/tcp_server
COPY lib /opt/tcp_server/lib
COPY config /opt/tcp_server/config

WORKDIR /opt/tcp_server

RUN elixir -S mix do deps.get, compile

CMD ["elixir", "-S", "mix", "run", "--no-halt"]
