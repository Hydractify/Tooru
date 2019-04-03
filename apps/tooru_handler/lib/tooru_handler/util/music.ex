defmodule Tooru.Handler.Util.Music do
  alias Crux.Structs.Permissions
  alias Tooru.Rpc.Cache

  def play_id_or_reason(user_id, %{voice_states: states} = guild) do
    bot_id = Application.fetch_env!(:tooru_handler, :id)

    case states do
      # Both in the same channel
      %{
        ^bot_id => %{channel_id: id},
        ^user_id => %{channel_id: id}
      } ->
        true

      # User connected, but bot is not (voice state cached)
      %{^user_id => %{channel_id: id}, ^bot_id => %{channel_id: nil}}
      when not is_nil(id) ->
        joinable_or_reason(bot_id, guild, id)

      # User is connected, but bot is not (no voice state cached)
      %{^user_id => %{channel_id: id}}
      when not is_nil(id) and not :erlang.is_map_key(bot_id, states) ->
        joinable_or_reason(bot_id, guild, id)

      %{^user_id => %{channel_id: u_id}, ^bot_id => %{channel_id: b_id}}
      when not is_nil(u_id) and u_id != b_id ->
        "You are connected to a different voice channel."

      _ ->
        "You are not connected to a voice channel."
    end
  end

  def play_id_or_reason(user_id, guild_id) do
    play_id_or_reason(user_id, Cache.fetch_guild!(guild_id))
  end

  def other_or_reason(user_id, %{voice_states: states}) do
    bot_id = Application.fetch_env!(:tooru_handler, :id)

    case states do
      # Both in the same channel
      %{
        ^bot_id => %{channel_id: id},
        ^user_id => %{channel_id: id}
      } ->
        true

      # Bot is not connected
      %{^bot_id => %{channel_id: nil}} ->
        true

      %{^bot_id => %{channel_id: _b_id}, ^user_id => %{channel_id: _u_id}} ->
        "You are in a different voice channel."
    end
  end

  def other_or_reason(user_id, guild_id) do
    other_or_reason(user_id, Cache.fetch_guild!(guild_id))
  end

  def joinable_or_reason(
        bot_id,
        %{voice_states: states} = guild,
        %{id: channel_id, user_limit: limit} = channel
      ) do
    permissions = Permissions.implicit(bot_id, guild, channel)

    if Permissions.has(permissions, [:view_channel, :connect]) do
      users_connected =
        states
        |> Enum.count(fn
          {_, %{channel_id: ^channel_id}} -> true
          _ -> false
        end)

      if limit != 0 and users_connected >= limit and
           not Permissions.has(permissions, :move_members) do
        "I do not have permissions to connect to your voice channel; It is full."
      else
        channel_id
      end
    else
      "I do not have permissions to connect to your voice channel."
    end
  end

  def joinable_or_reason(bot_id, guild, channel_id) do
    joinable_or_reason(bot_id, guild, Cache.fetch_channel!(channel_id))
  end
end
