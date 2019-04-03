defmodule Tooru.Rpc.Gateway do
  @moduledoc """
    Provides an interface to communicate with the `gateway` node in a comfortable manner.
  """

  alias Tooru.Rpc
  require Tooru.Rpc

  @name Tooru.Gateway

  @doc """
    Gets a list of shard ids currently being handled.
  """
  @spec shards() :: [non_neg_integer()]
  def shards()
      when Rpc.is_none(node())
      when Rpc.is_gateway(node()) do
    @name
    |> Crux.Gateway.Connection.Producer.producers()
    |> Map.keys()
  end

  def shards() do
    Rpc.call(Rpc.gateway(), __MODULE__, :shards, [])
  end

  @doc """
    Gets the pid of a producer by shard_ d.
  """
  @spec producer(shard_id :: non_neg_integer()) :: pid()
  def producer(shard_id)
      when Rpc.is_none(node())
      when Rpc.is_gateway(node()) do
    @name
    |> Crux.Gateway.Connection.Producer.producers()
    |> Map.fetch!(shard_id)
  end

  def producer(shard_id) do
    Rpc.call(Rpc.gateway(), __MODULE__, :producer, [shard_id])
  end

  @doc """
    Sends a voice state update to the given shard.
  """
  @spec voice_state_update(
          shard_id :: non_neg_integer(),
          guild_id :: Crux.Rest.snowflake(),
          channel_id :: Crux.Rest.snowflake(),
          states :: list()
        ) :: :ok
  def voice_state_update(shard_id, guild_id, channel_id \\ nil, states \\ [])

  def voice_state_update(shard_id, guild_id, channel_id, states)
      when Rpc.is_none(node())
      when Rpc.is_gateway(node()) do
    command = Crux.Gateway.Command.voice_state_update(guild_id, channel_id, states)
    send_command(shard_id, command)
  end

  def voice_state_update(shard_id, guild_id, channel_id, states) do
    Rpc.call(Rpc.gateway(), __MODULE__, :voice_state_update, [
      shard_id,
      guild_id,
      channel_id,
      states
    ])
  end

  @doc """
    Sends a `Crux.Gateway.Command.command()` to the given shard.
  """
  @spec send_command(shard_id :: non_neg_integer(), Crux.Gateway.Command.command()) :: :ok
  def send_command(shard_id, command)
      when Rpc.is_none(node())
      when Rpc.is_gateway(node()) do
    Crux.Gateway.Connection.send_command(@name, shard_id, command)
  end

  def send_command(shard_id, command) do
    Rpc.call(Rpc.gateway(), __MODULE__, :send_command, [shard_id, command])
  end
end
