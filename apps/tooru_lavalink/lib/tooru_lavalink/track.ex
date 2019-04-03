defmodule Tooru.Lavalink.Track do
  # TODO
  defstruct [
    :track,
    :author,
    :identifier,
    :is_seekable,
    :is_stream,
    :length,
    :position,
    :title,
    :uri,
    :requester
  ]

  # TODO
  @me %Crux.Structs.User{
    avatar: "8f9ca449333e8d61d6d326f13e46689a",
    bot: true,
    discriminator: "2505",
    id: 532_267_324_363_767_869,
    username: "Tooru β"
  }

  alias Crux.Rest.CDN

  @type t :: %__MODULE__{}

  def create(tracks, requester) when is_list(tracks), do: Enum.map(tracks, &create(&1, requester))

  def create(
        %{
          "info" => %{"isSeekable" => is_seekable, "isStream" => is_stream} = info,
          "track" => track
        },
        requester
      ) do
    data =
      info
      |> Map.drop(["isSeekable", "isStream"])
      |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
      |> Map.merge(%{
        is_seekable: is_seekable,
        is_stream: is_stream,
        track: track,
        requester: requester
      })

    struct(__MODULE__, data)
  end

  @spec to_markdown_uri(t()) :: String.t()
  def to_markdown_uri(%__MODULE__{title: title, uri: uri}) do
    "[#{title}](#{uri})"
  end

  @spec to_length(t()) :: String.t()
  def to_length(%__MODULE__{length: length}), do: format_milliseconds(length)

  @spec to_info(t()) :: String.t()
  def to_info(%__MODULE__{} = track) do
    """
    #{to_markdown_uri(track)}
    Length: #{to_length(track)}
    """
  end

  @spec to_embed(t()) :: Crux.Rest.embed()
  def to_embed(
        %__MODULE__{
          requester: %{username: username, discriminator: discriminator, id: id} = requester
        } = track,
        type \\ nil
      ) do
    %{
      author: %{
        name: "#{username}##{discriminator} (#{id})",
        icon_url: CDN.user_avatar(requester)
      },
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      image: %{
        url: to_image_uri(track)
      }
    }
    |> Map.merge(type_data(type, track))
    |> put_in([:footer, :icon_url], CDN.user_avatar(@me))
  end

  @spec to_image_uri(t()) :: String.t() | nil
  def to_image_uri(%{uri: "https://www.youtube.com/watch?v=" <> _id} = track) do
    "https://img.youtube.com/vi/#{track.identifier}/mqdefault.jpg"
  end

  def to_image_uri(%{uri: "https://twitch.tv/" <> _channel} = track) do
    "https://static-cdn.jtvnw.net/previews-ttv/live_user_#{String.downcase(track.author)}-320x180.jpg"
  end

  # Soundcloud, why do you not offer a url scheme? :c
  def to_image_uri(_other), do: nil

  @spec format_milliseconds(integer()) :: String.t()
  def format_milliseconds(time), do: time |> div(1000) |> format_seconds()

  @spec format_seconds(integer()) :: String.t()
  def format_seconds(time) when time > 86_400 do
    rest =
      time
      |> rem(86_400)
      |> format_seconds()

    "#{div(time, 86_400)} days #{rest}"
  end

  def format_seconds(time) when time > 3_600 do
    rest =
      time
      |> rem(3_600)
      |> format_seconds()

    "#{div(time, 3_600)}:#{rest}"
  end

  def format_seconds(time) do
    seconds =
      time
      |> rem(60)
      |> Integer.to_string()
      |> String.pad_leading(2, "0")

    minutes =
      time
      |> div(60)
      |> Integer.to_string()
      |> String.pad_leading(2, "0")

    "#{minutes}:#{seconds}"
  end

  defp type_data(nil, track), do: %{description: to_markdown_uri(track)}

  defp type_data("save", track) do
    %{
      color: 0x7EB7E4,
      description: "💾 " <> to_info(track),
      footer: %{
        text: "saved, just for you."
      }
    }
  end

  defp type_data("play", track) do
    %{
      color: 0x00FF08,
      description: "**>>** " <> to_info(track),
      footer: %{
        text: "is now being played."
      }
    }
  end

  defp type_data("add", track) do
    %{
      color: 0xFFFF00,
      description: "**++** " <> to_info(track),
      footer: %{
        text: "has been added."
      }
    }
  end

  defp type_data("np", track) do
    %{
      color: 0x0800FF,
      description: "**>>** " <> to_info(track),
      footer: %{
        text: "currently playing."
      }
    }
  end
end
