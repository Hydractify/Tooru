defmodule Tooru.Handler.Command.Remove do
  alias :queue, as: Queue

  alias Tooru.Lavalink.Command
  alias Tooru.Handler.Util.Music
  alias Tooru.Rpc.Lavalink

  use Tooru.Handler.Command

  def handle(_, [], _shard_id), do: "You need to provide a position to remove."

  def handle(message, [pos | _], _shard_id) do
    pos
    |> Integer.parse()
    |> case do
      {pos, ""} ->
        continue(message, pos)

      _ ->
        "You need to provide a position of a song in the queue to remove."
    end
  end

  def continue(%{author: %{id: user_id}, guild_id: guild_id}, pos) do
    with true <- Music.other_or_reason(user_id, guild_id) do
      Lavalink.get_name()
      |> ExLink.get_player(guild_id)
      |> case do
        :error ->
          "Not connected"

        player ->
          Command.update_queue(player, fn queue ->
            queue = Queue.to_list(queue)

            track = Enum.at(queue, pos)

            queue =
              queue
              |> List.delete_at(pos)
              |> Queue.from_list()

            {queue, track}
          end)
          |> case do
            nil ->
              "No track with that position in the queue."

            track ->
              "Removed #{track.title} from the queue."
          end
      end
    end
  end
end
