defmodule Tooru.Handler.Command.Resume do
  alias Tooru.Lavalink.Command
  alias Tooru.Handler.Util.Music
  alias Tooru.Rpc.Lavalink

  use Tooru.Handler.Command

  def handle(%{author: %{id: user_id}, guild_id: guild_id}, _args, _shard_id) do
    with true <- Music.other_or_reason(user_id, guild_id) do
      Lavalink.get_name()
      |> ExLink.get_player(guild_id)
      |> case do
        :error ->
          "Not connected"

        player ->
          success = Command.resume(player)

          if success do
            "Resumed"
          else
            "Already playing"
          end
      end
    end
  end
end
