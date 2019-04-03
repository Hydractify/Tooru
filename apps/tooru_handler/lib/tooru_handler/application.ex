defmodule Tooru.Handler.Application do
  @moduledoc false

  alias Tooru.Rpc.Cache

  use Application

  @registry Tooru.Handler.Registry

  def registry(), do: @registry

  def start(_type, _args) do
    Logger.add_backend(Sentry.LoggerBackend)
    |> case do
      {:ok, _} ->
        nil

      {:error, :already_present} ->
        nil
    end

    consumers =
      for {shard_id, _} <- Cache.producers() do
        Supervisor.child_spec(
          {Tooru.Handler.Consumer, shard_id},
          id: {:consumer, shard_id}
        )
      end

    children = [{Registry, keys: :unique, name: @registry} | consumers]

    opts = [strategy: :one_for_one, name: Tooru.Handler.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
