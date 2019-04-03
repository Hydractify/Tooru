defmodule Tooru.Rpc.Cache do
  @moduledoc """
    Provides an interface to communicate with the `cache` node in a comfortable manner.
  """

  alias Tooru.Rpc
  require Tooru.Rpc

  @name Tooru.Cache

  @doc """
    Fetches a channel by id
  """
  @spec fetch_channel!(channel_id :: Crux.Rest.snowflake()) ::
          Crux.Structs.Channel.t() | no_return()
  def fetch_channel!(channel_id)
      when Rpc.is_none(node())
      when Rpc.is_cache(node()) do
    # Silences the dialyzer
    mod = Crux.Cache.Channel
    mod.fetch!(channel_id)
  end

  def fetch_channel!(channel_id) do
    Rpc.call(Rpc.cache(), __MODULE__, :fetch_channel!, [channel_id])
  end

  @doc """
    Fetches a guild by id
  """
  @spec fetch_guild!(channel_id :: Crux.Rest.snowflake()) :: Crux.Structs.Guild.t() | no_return()
  def fetch_guild!(guild_id)
      when Rpc.is_none(node())
      when Rpc.is_cache(node()) do
    # Silences the dialyzer
    mod = Crux.Cache.Guild
    mod.fetch!(guild_id)
  end

  def fetch_guild!(guild_id) do
    Rpc.call(Rpc.cache(), __MODULE__, :fetch_guild!, [guild_id])
  end

  @doc """
    Gets a map of producers with pids keyed under shard id.
  """
  @spec producers() :: %{non_neg_integer() => pid()}
  def producers() do
    get_name()
    |> Supervisor.which_children()
    |> Enum.flat_map(fn
      {{:producer, id}, pid, _type, _module} ->
        [{id, pid}]

      _ ->
        []
    end)
    |> Map.new()
  end

  def producer(shard_id) do
    producers()
    |> Map.fetch!(shard_id)
  end

  @doc """
    Gets the name of the cache supervisor.
  """
  @spec get_name() :: atom() | {atom(), node()}
  def get_name()
      when Rpc.is_none(node())
      when Rpc.is_cache(node()) do
    @name
  end

  def get_name() do
    {@name, Rpc.cache()}
  end
end
