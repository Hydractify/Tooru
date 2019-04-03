defmodule Tooru.Lavalink.Application do
  @moduledoc false

  use Application

  @url "localhost:2333"
  @authorization "12345"
  @shard_count 1

  def start(_type, _args) do
    Logger.add_backend(Sentry.LoggerBackend)
    |> case do
      {:ok, _} ->
        nil

      {:error, :already_present} ->
        nil
    end

    user_id = Application.fetch_env!(:tooru_lavalink, :id)

    children = [
      {Tooru.Lavalink.Player,
       {%{
          url: @url,
          authorization: @authorization,
          shard_count: @shard_count,
          user_id: user_id
        }, name: Tooru.Lavalink}}
    ]

    opts = [strategy: :one_for_one, name: Tooru.Lavalink.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
