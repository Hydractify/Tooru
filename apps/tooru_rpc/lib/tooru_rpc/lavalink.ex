defmodule Tooru.Rpc.Lavalink do
  @moduledoc """
    Provides an interface to communicate with the `Lavalink` node in a comfortable manner.
  """

  alias Tooru.Rpc.Gateway
  alias Tooru.Rpc
  require Tooru.Rpc

  @name Tooru.Lavalink

  @doc """
    Resolves an identifier and fetches tracks in one go.
  """
  def resolve_and_fetch(url, requester)
      when Rpc.is_none(node())
      when Rpc.is_lavalink(node()) do
    # Silences the dialyzer
    mod = Tooru.Lavalink.Rest

    mod.resolve_identifier(url)
    |> mod.fetch_tracks(requester)
  end

  def resolve_and_fetch(url, requester) do
    Rpc.call(Rpc.lavalink(), __MODULE__, :resolve_and_fetch, [url, requester])
  end

  @doc """
    Forwards an event to the Lavalink node.
  """
  def forward(event)
      when Rpc.is_none(node())
      when Rpc.is_lavalink(node()) do
    @name
    |> GenServer.whereis()
    |> case do
      pid when is_pid(pid) ->
        ExLink.Connection.forward(pid, event)

      _ ->
        :ignore
    end
  end

  def forward(event) do
    Rpc.call(Rpc.lavalink(), __MODULE__, :forward, [event])
  end

  @doc """
    Ensures that the bot is connected to the given voice channel and that a player for it exists.
  """
  @spec ensure_connected(
          shard_id :: non_neg_integer(),
          guild_id :: Crux.Rest.snowflake(),
          channel_id :: Crux.Rest.snowflake()
        ) :: pid()
  def ensure_connected(shard_id, guild_id, channel_id) do
    get_name()
    |> ExLink.get_player(guild_id)
    |> case do
      pid when is_pid(pid) ->
        pid

      :error ->
        Gateway.voice_state_update(shard_id, guild_id, channel_id)

        ExLink.ensure_player(get_name(), guild_id)
    end
  end

  @doc """
    Gets the name of the `ExLink` process on the lavalink node.
    If applicable returns a `{name, node}` tuple.
  """
  @spec get_name() :: atom() | {atom(), node()}
  def get_name()
      when Rpc.is_none(node())
      when Rpc.is_lavalink(node()) do
    @name
  end

  def get_name() do
    {@name, Rpc.lavalink()}
  end
end
