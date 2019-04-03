defmodule Tooru.Rest.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    Logger.add_backend(Sentry.LoggerBackend)
    |> case do
      {:ok, _} ->
        nil

      {:error, :already_present} ->
        nil
    end

    children = [{Tooru.Rest, %{token: Application.fetch_env!(:tooru_rest, :token)}}]

    opts = [strategy: :one_for_one, name: Tooru.Rest.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
