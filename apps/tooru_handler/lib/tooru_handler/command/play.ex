defmodule Tooru.Handler.Command.Play do
  alias Tooru.Rpc.Lavalink
  alias Tooru.Lavalink.{Command, Track}
  alias Tooru.Handler.Util.Music

  use Tooru.Handler.Command

  def handle(
        %{author: %{id: user_id} = author, guild_id: guild_id, channel_id: channel_id},
        args,
        shard_id
      ) do
    case Music.play_id_or_reason(user_id, guild_id) do
      reason when is_binary(reason) ->
        reason

      id_or_true ->
        args
        |> Enum.join(" ")
        |> Lavalink.resolve_and_fetch(author)
        |> case do
          {:error, _error} ->
            "An error occured"

          {:ok, :error} ->
            "An error occured"

          {:ok, :not_found} ->
            "Could not find anything"

          {:ok, tracks} ->
            player = Lavalink.ensure_connected(shard_id, guild_id, id_or_true)

            Command.register(player, shard_id, channel_id)
            start = Command.queue(player, tracks)

            unless start do
              embed =
                case tracks do
                  [track | _] ->
                    Track.to_embed(track, "add")

                  track ->
                    Track.to_embed(track, "add")
                end

              [embed: embed]
            end
        end
    end
  end
end
