defmodule Tooru.Handler.Consumer do
  @moduledoc false

  alias Tooru.Rpc.{Cache, Lavalink}
  alias Tooru.Handler.Command

  use GenStage

  @registry Tooru.Handler.Application.registry()

  def start_link(shard_id) do
    name = {:via, Registry, {@registry, shard_id}}
    GenStage.start_link(__MODULE__, shard_id, name: name)
  end

  def init(shard_id) do
    pid = Cache.producer(shard_id)

    {:consumer, shard_id, subscribe_to: [pid]}
  end

  def handle_events(events, _from, state) do
    for {type, data, shard_id} <- events do
      handle_event(type, data, shard_id)
    end

    {:noreply, [], state}
  end

  def handle_event(:MESSAGE_CREATE, message, shard_id) do
    Command.handle(message, shard_id)
  end

  def handle_event(
        :VOICE_STATE_UPDATE,
        {_, event},
        _shard_id
      ) do
    event
    |> Map.from_struct()
    |> Lavalink.forward()
  end

  def handle_event(
        :VOICE_SERVER_UPDATE,
        event,
        _shard_id
      ) do
    Lavalink.forward(event)
  end

  def handle_event(_type, _data, _shard_id), do: nil
end
