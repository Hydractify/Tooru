defmodule Tooru.Lavalink.Command do
  @moduledoc """
    Sends commands to a player.
  """
  alias Tooru.Lavalink.{Player, Track}

  @type player :: pid()

  @spec register(player(), shard_id :: non_neg_integer(), channel_id :: ExLink.Payload.id()) ::
          :ok | :ignore
  def register(player, shard_id, channel_id),
    do: do_call(player, {:register, shard_id, channel_id})

  @spec get_queue(player()) :: {Player.queue(), position :: integer()}
  def get_queue(player), do: do_call(player, :queue)

  @spec update_queue(
          player(),
          (Player.queue() -> Player.queue() | {Player.queue(), term()})
        ) :: :ok
  def update_queue(player, fun), do: do_call(player, {:queue, fun})

  @spec queue(player(), Track.t() | [Track.t()]) :: boolean()
  def queue(player, tracks), do: do_call(player, {:queue, tracks})

  @spec skip(player()) :: Track.t() | :error
  def skip(player), do: do_call(player, :skip)

  @spec stop(player()) :: Track.t() | :error
  def stop(player), do: do_call(player, :stop)

  @spec pause(player()) :: boolean()
  def pause(player), do: do_call(player, :pause)

  @spec resume(player()) :: boolean()
  def resume(player), do: do_call(player, :resume)

  @spec do_call(player(), term()) :: term()
  defp do_call(player, command) do
    ExLink.Player.call(player, {:command, command})
  end
end
