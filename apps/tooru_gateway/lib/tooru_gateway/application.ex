defmodule Tooru.Gateway.Application do
  @moduledoc false

  alias Tooru.Rpc.Rest

  use Application

  @name Tooru.Gateway

  def start(_type, _args) do
    Logger.add_backend(Sentry.LoggerBackend)
    |> case do
      {:ok, _} ->
        nil

      {:error, :already_present} ->
        nil
    end

    {:ok, data} = fetch_data()

    data = Map.put(data, :token, Application.fetch_env!(:tooru_gateway, :token))

    children = [{Crux.Gateway, {data, name: @name}}]

    opts = [strategy: :one_for_one, name: Tooru.Gateway.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # TODO: Probably :rpc this later
  defp fetch_data() do
    {:ok, %{"shards" => shard_count, "url" => url}} = Rest.gateway_bot()

    {:ok, %{shard_count: shard_count, url: url}}
  end
end
