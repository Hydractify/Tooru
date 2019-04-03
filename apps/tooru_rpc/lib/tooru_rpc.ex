defmodule Tooru.Rpc do
  @moduledoc """
    Module providing node names, is_ macros, and a call function.
  """

  alias Tooru.Rpc.RpcError

  @rest :"tooru_rest@127.0.0.1"
  @gateway :"tooru_gateway@127.0.0.1"
  @cache :"tooru_cache@127.0.0.1"
  @handler :"tooru_handler@127.0.0.1"
  @lavalink :"tooru_lavalink@127.0.0.1"
  @none :nonode@nohost

  @doc "Returns the atom for the rest node."
  def rest(), do: @rest
  @doc "Returns the atom for the gateway node."
  def gateway(), do: @gateway
  @doc "Returns the atom for the cache node."
  def cache(), do: @cache
  @doc "Returns the atom for the handler node."
  def handler(), do: @handler
  @doc "Returns the atom for the lavalink node."
  def lavalink(), do: @lavalink
  @doc "Returns the atom for the unconnected node."
  def none(), do: @none

  @doc "Convenience guard returning whether `x` is the node `rest`."
  defguard is_rest(x) when x == @rest
  @doc "Convenience guard returning whether `x` is the node `gateway`."
  defguard is_gateway(x) when x == @gateway
  @doc "Convenience guard returning whether `x` is the node `cache`."
  defguard is_cache(x) when x == @cache
  @doc "Convenience guard returning whether `x` is the node `handler`."
  defguard is_handler(x) when x == @handler
  @doc "Convenience guard returning whether `x` is the node `lavalink`."
  defguard is_lavalink(x) when x == @lavalink
  @doc "Convenience guard returning whether `x` is an unconnected node."
  defguard is_none(x) when x == @none

  @doc """
    Calls a `node` executing a `fun` in a `mod` with the given ´args`.

    Internally uses `:rpc.call/4`.

    Raises when:
    * The called function raises
    * The target node is down
    * Another other rpc error occurs
  """
  @spec call(node(), module(), fun :: atom(), args :: list()) :: term() | no_return()
  def call(node, mod, fun, args)
      when is_atom(node) and is_atom(mod) and is_atom(fun) and is_list(args) do
    :rpc.call(node, mod, fun, args)
    |> case do
      {:badrpc, {:EXIT, {kind, stacktrace}}} ->
        exception = Exception.normalize(:error, kind, stacktrace)

        reraise RpcError, [exception, args], stacktrace

      {:badrpc, :nodedown} ->
        raise RpcError, ["The target node \"#{node}\" is down", args]

      {:badrpc, reason} ->
        raise RpcError, [
          """
          received an unexpected ":badrcp"
          #{inspect(reason)}
          target:
          #{node}
          """,
          args
        ]

      other ->
        other
    end
  end
end
