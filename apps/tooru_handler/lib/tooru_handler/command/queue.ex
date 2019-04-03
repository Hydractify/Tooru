defmodule Tooru.Handler.Command.Queue do
  alias :queue, as: Queue

  alias Tooru.Lavalink.{Command, Track}
  alias Tooru.Rpc.Lavalink

  use Tooru.Handler.Command

  def handle(message, [], shard_id), do: handle(message, ["1"], shard_id)

  def handle(%{guild_id: guild_id}, [page | _], _shard_id) do
    Lavalink.get_name()
    |> ExLink.get_player(guild_id)
    |> case do
      :error ->
        "Not connected"

      player ->
        page = parse_page(page)

        {queue, current_time} =
          Command.get_queue(player)
          # |> IO.inspect()

        [current | _] = queue = Queue.to_list(queue)
        total_songs = length(queue)

        total_length =
          queue
          |> Enum.reduce(0, fn track, acc -> acc + track.length end)
          |> Track.format_milliseconds()

        pages = div(total_songs - 1, 10) + 1

        page = Enum.min([page, pages])

        songs = page(queue, page)

        current_length = Track.to_length(current)

        current_time = Track.format_milliseconds(current_time)

        embed = %{
          color: 0x0800FF,
          title: "Queued up Songs: #{total_songs} | Queue length: #{total_length}",
          description: """
          **Currently playing**
          #{Track.to_markdown_uri(current)}
          **Time**: (`#{current_time}`/ `#{current_length}`)

          **Queue**
          #{songs}
          """,
          thumbnail: %{
            url: Track.to_image_uri(current)
          },
          footer: %{
            # TODO
            icon_url: nil,
            text: "Page #{page} of #{pages}"
          }
        }

        [embed: embed]
    end
  end

  defp page(queue, page) do
    from = (page - 1) * 10 + 1

    queue
    |> Enum.slice(from..(from + 9))
    |> Enum.with_index(from)
    |> Enum.map_join("\n", fn {track, index} ->
      "`#{index}.` #{Track.to_length(track)} - #{Track.to_markdown_uri(track)}"
    end)
  end

  defp parse_page(page) do
    page
    |> Integer.parse()
    |> case do
      {page, ""} when page < 1 ->
        1

      {page, ""} ->
        page

      :error ->
        1
    end
  end
end
