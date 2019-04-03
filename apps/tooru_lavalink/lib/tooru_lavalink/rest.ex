defmodule Tooru.Lavalink.Rest do
  @moduledoc false

  @url "http://localhost:2333/loadtracks"
  @authorization "12345"

  alias Tooru.Lavalink.Track

  @spec resolve_identifier(url :: String.t()) :: String.t()
  def resolve_identifier(url) do
    url =
      if String.starts_with?(url, "<") and String.ends_with?(url, ">") do
        String.slice(url, 1..-2)
      else
        url
      end

    cond do
      Regex.match?(~r{^(?:https?://)?(?:www\.)?youtube\.com/playlist\?list=.+}, url) or
        Regex.match?(~r{^(?:https?://)?(?:www\.)?youtube\.com/watch\?v=.+}, url) or
        Regex.match?(~r{^(?:https?://)?(?:www\.)?soundcloud.com/.+}, url) or
        Regex.match?(~r{^(?:https?://)?(?:www\.)?twitch\.tv/.+}, url) or
          Regex.match?(~r{^(?:https?://)?(?:www\.)?youtu\.be/.+}, url) ->
        url

      true ->
        "ytsearch:#{url}"
    end
  end

  @spec fetch_tracks(identifier :: String.t(), requester :: Crux.Structs.User.t()) ::
          {:ok, Track.t() | [Track.t()] | :not_found | :error} | {:error, term()}
  def fetch_tracks(identifier, requester \\ nil) do
    @url
    |> HTTPoison.get(
      [{"Authorization", @authorization}],
      params: [identifier: identifier]
    )
    |> case do
      {:ok, %{body: body}} ->
        body
        |> Poison.decode()
        |> handle_response(requester)

      {:error, _error} = tuple ->
        tuple
    end
  end

  @type track :: map()

  @spec handle_response(
          response :: map(),
          requester :: Crux.Structs.User.t()
        ) :: track() | [track()] | :not_found | :error
  defp handle_response({:error, _error} = error, _requester), do: error

  defp handle_response({:ok, response}, requester),
    do: {:ok, handle_response(response, requester)}

  defp handle_response(
         %{
           "loadType" => "TRACK_LOADED",
           "tracks" => [track | _]
         },
         requester
       ) do
    track
    |> Track.create(requester)
  end

  defp handle_response(
         %{
           "loadType" => "PLAYLIST_LOADED",
           "playlistInfo" => %{"selectedTrack" => -1},
           "tracks" => tracks
         },
         requester
       ) do
    tracks
    |> Track.create(requester)
  end

  defp handle_response(
         %{
           "loadType" => "PLAYLIST_LOADED",
           "playlistInfo" => %{"selectedTrack" => track},
           "tracks" => tracks
         },
         requester
       ) do
    tracks
    |> Enum.at(track)
    |> Track.create(requester)
  end

  defp handle_response(
         %{
           "loadType" => "SEARCH_RESULT",
           "tracks" => [track | _]
         },
         requester
       ) do
    track
    |> Track.create(requester)
  end

  defp handle_response(
         %{
           "loadType" => "NO_MATCHES"
         },
         _requester
       ) do
    :not_found
  end

  defp handle_response(
         %{
           "loadType" => "LOAD_FAILED"
         },
         _requester
       ) do
    :error
  end
end
