defmodule Tooru.Lavalink.Player do
  alias ExLink.Message

  alias Tooru.Rpc.{Gateway, Rest}
  alias Tooru.Lavalink.Track

  alias :queue, as: Queue

  use ExLink.Player

  @type queue :: Queue.queue(Track.t() | [Track.t()])

  defstruct(
    guild_id: nil,
    queue: nil,
    channel_id: nil,
    position: -1,
    paused: nil,
    message: nil,
    shard_id: nil
  )

  def init(_client, guild_id) do
    IO.inspect(
      "[---------------------------------------] INIT #{inspect(self())} [---------------------------------------]"
    )

    state = %__MODULE__{
      guild_id: guild_id,
      queue: Queue.new()
    }

    {:ok, state}
  end

  defp send(message), do: ExLink.Connection.send(Tooru.Lavalink, message)

  ### Commands

  def handle_command(:resume, %{paused: false} = state), do: {:reply, false, state}

  def handle_command(:resume, %{guild_id: guild_id} = state) do
    false
    |> Message.pause(guild_id)
    |> send()

    {:reply, true, %{state | paused: false}}
  end

  def handle_command(:pause, %{paused: true} = state), do: {:reply, false, state}

  def handle_command(:pause, %{guild_id: guild_id} = state) do
    true
    |> Message.pause(guild_id)
    |> send()

    {:reply, true, %{state | paused: true}}
  end

  def handle_command(:skip, %{guild_id: guild_id, queue: queue} = state) do
    guild_id
    |> Message.stop()
    |> send()

    track_or_empty =
      queue
      |> Queue.peek()
      |> case do
        {:value, track} -> track
        :empty -> :empty
      end

    {:reply, track_or_empty, state}
  end

  def handle_command(:stop, %{guild_id: guild_id, queue: queue} = state) do
    guild_id
    |> Message.stop()
    |> send()

    track_or_empty =
      queue
      |> Queue.peek()
      |> case do
        {:value, track} -> track
        :empty -> :empty
      end

    {:reply, track_or_empty, %{state | queue: Queue.new()}}
  end

  def handle_command({:register, shard_id, channel_id}, %{channel_id: nil} = state) do
    {:reply, :ok, %{state | channel_id: channel_id, shard_id: shard_id}}
  end

  def handle_command({:register, _shard_id, _channel_id}, state) do
    {:reply, :ignore, state}
  end

  def handle_command(:queue, state), do: {:reply, {state.queue, state.position}, state}

  def handle_command({:queue, fun}, %{queue: queue} = state) when is_function(fun) do
    {queue, res} =
      queue
      |> fun.()
      |> case do
        {_queue, _res} = res ->
          res

        queue ->
          {queue, queue}
      end

    {:reply, res, %{state | queue: queue}}
  end

  def handle_command({:queue, [track | _] = tracks}, %{queue: queue} = state)
      when is_list(tracks) do
    start = Queue.is_empty(queue)

    queue = Enum.reduce(tracks, queue, &Queue.in(&1, &2))

    state = %{state | queue: queue}

    state =
      if start do
        play(track, state)
      else
        state
      end

    {:reply, start, state}
  end

  def handle_command({:queue, track}, state), do: handle_command({:queue, [track]}, state)

  def handle_call({:command, command}, _from, state) do
    handle_command(command, state)
  end

  ### End Command

  ### call/cast/info/global dispatch

  def handle_call(msg, _from, state) do
    IO.inspect(msg, label: "handle_call")

    {:reply, :error, state}
  end

  def handle_cast(msg, state) do
    IO.inspect(msg, label: "handle_cast")

    {:noreply, state}
  end

  def handle_info(msg, state) do
    IO.inspect(msg, label: "handle_info")

    {:noreply, state}
  end

  def handle_dispatch(_data, nil) do
    # IO.inspect(data, label: "global-handle_dispatch")
  end

  # def handle_dispatch(data, state) do
  #   IO.inspect(data, label: "handle_dispatch")

  #   {:noreply, state}
  # end

  ### End call/cast/info/global dispatch

  ### Handled Dispatches

  def handle_dispatch(
        %{
          "op" => "event",
          "type" => "WebSocketClosedEvent",
          "reason" => reason,
          "byRemote" => by_remote,
          "code" => code
        },
        state
      ) do
    require Logger

    Logger.warn(fn ->
      """
      [Tooru][Lavalink][Player]: WebSocket closed:
      Code: #{code}
      Reason: #{reason}
      By remote: #{by_remote}
      """
    end)

    {:stop, :normal, state}
  end

  def handle_dispatch(
        %{
          "op" => "playerUpdate",
          "state" => %{"position" => position}
        },
        state
      ) do
    # IO.inspect(position, label: :position)
    state = %{state | position: position}

    {:noreply, state}
  end

  def handle_dispatch(
        %{
          "op" => "event",
          "reason" => reason,
          "type" => "TrackEndEvent"
        },
        state
      ) do
    state =
      state
      |> Map.put(:position, -1)
      |> Map.put(:playing, nil)
      |> delete_message()

    if reason == "REPLACED" do
      {:noreply, state}
    else
      with false <- Queue.is_empty(state.queue),
           queue <- Queue.drop(state.queue),
           {:value, track} <- Queue.peek(queue) do
        state = play(track, state)

        {:noreply, %{state | queue: queue}}
      else
        other ->
          IO.inspect(other, label: :other)

          Gateway.voice_state_update(state.shard_id, state.guild_id)

          {:stop, :normal, state}
      end
    end
  end

  ### End Handled Dispatches

  defp delete_message(%{message: nil} = state), do: state

  defp delete_message(%{message: message} = state) do
    message
    |> Rest.delete_message()

    %{state | message: nil}
  end

  defp play(track, %{guild_id: guild_id, channel_id: channel_id} = state) do
    state =
      if channel_id do
        embed = Track.to_embed(track, "play")

        message = Rest.create_message!(channel_id, embed: embed)

        %{state | message: message}
      else
        state
      end

    track.track
    |> Message.play(guild_id)
    |> send()

    %{state | paused: false}
  end
end
