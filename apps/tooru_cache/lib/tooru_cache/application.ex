defmodule Tooru.Cache.Application do
  use Application

  alias Tooru.Cache.{Consumer, Producer}
  alias Tooru.Rpc.Gateway

  @name Tooru.Cache
  @registry Tooru.Cache.Registry

  def start(_type, _args) do
    children =
      Gateway.shards()
      |> Enum.flat_map(fn shard_id ->
        [
          Supervisor.child_spec({Consumer, shard_id}, id: {:consumer, shard_id}),
          Supervisor.child_spec({Producer, shard_id}, id: {:producer, shard_id})
        ]
      end)

    children = [
      {Registry, keys: :unique, name: @registry},
      Crux.Cache.Default
      | children
    ]

    Supervisor.start_link(children, strategy: :rest_for_one, name: @name)
  end
end
