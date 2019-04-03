defmodule Tooru.Handler.Command.Eval do
  use Tooru.Handler.Command

  def handle(%{author: %{id: author_id}} = message, args, _shard_id) do
    if author_id in Application.fetch_env!(:tooru_handler, :owners) do
      {res, _binding} =
        try do
          args
          |> Enum.join(" ")
          |> Code.eval_string(message: message)
        rescue
          e -> {Exception.format(:error, e, __STACKTRACE__), nil}
        end

      res =
        case res do
          res when is_binary(res) -> res
          res -> inspect(res)
        end
        |> String.slice(0, 1950)

      "```elixir\n#{res}\n```"
    end
  end
end
