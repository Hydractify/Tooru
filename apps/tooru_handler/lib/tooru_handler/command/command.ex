defmodule Tooru.Handler.Command do
  @callback handle(
              message :: map(),
              args :: [String.t()],
              shard_id :: non_neg_integer()
            ) :: nil | Crux.Rest.create_message_data()

  defmacro __using__(_ \\ []) do
    quote do
      @behaviour Tooru.Handler.Command
    end
  end

  alias Tooru.Rpc.Rest

  alias Tooru.Handler.Command

  @prefix "__"

  @commands %{
    "eval" => Command.Eval,
    "pause" => Command.Pause,
    "play" => Command.Play,
    "queue" => Command.Queue,
    "remove" => Command.Remove,
    "resume" => Command.Resume,
    "skip" => Command.Skip,
    "stop" => Command.Stop
  }

  def commands(), do: @commands

  def handle(%{guild_id: nil}, _shard_id), do: nil
  def handle(%{author: %{bot: true}}, _shard_id), do: nil

  def handle(%{content: @prefix <> rest} = message, shard_id) do
    [command | args] = String.split(rest, ~r{ +})

    command = String.downcase(command)

    res =
      case @commands do
        %{^command => mod} ->
          mod.handle(message, args, shard_id)

        _ ->
          nil
      end

    case res do
      nil ->
        nil

      content when is_binary(content) ->
        Rest.create_message!(message.channel_id, content: res)

      other ->
        Rest.create_message!(message.channel_id, other)
    end
  end

  def handle(_, _), do: nil
end
