defmodule Tooru.Cache.Consumer do
  @moduledoc """
    Handles consuming and processing of events received from the gateway.
    To consume those processed events subscribe with a consumer to a `Crux.Base.Producer`.
  """

  alias Tooru.Rpc.Gateway
  alias Tooru.Cache.Producer

  use GenStage

  @registry Tooru.Cache.Registry

  @doc false
  def start_link(shard_id) do
    name = {:via, Registry, {@registry, shard_id}}
    GenStage.start_link(__MODULE__, shard_id, name: name)
  end

  @doc false
  def init(shard_id) do
    require Logger

    pid = Gateway.producer(shard_id)
    Logger.info("[Bot][Cache][Consumer]: Connected to gateway producer for shard #{shard_id}")
    {:consumer, nil, subscribe_to: [pid]}
  end

  @doc false
  def handle_events(events, _from, nil) do
    for {type, data, shard_id} <- events,
        value <- Crux.Base.Processor.process_event(type, data, shard_id, Crux.Cache.Default) |> List.wrap(),
        value != nil do
      Producer.dispatch({type, value, shard_id})
    end

    {:noreply, [], nil}
  end

  def handle_events(events, from, _other), do: handle_events(events, from, nil)

  @doc false

  def handle_cancel({:down, :noconnection}, _, nil) do
    require Logger

    Logger.warn("[Bot][Cache][Consumer]: Gateway producer down, waiting 10 seconds.")
    Process.sleep(10_000)

    {:noreply, [], nil}
  end
end
