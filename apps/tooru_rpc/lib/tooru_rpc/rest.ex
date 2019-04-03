defmodule Tooru.Rpc.Rest do
  @moduledoc """
    Provides an interface to communicate with the `rest` node in a comfortable manner.

    Functions can be used like always, if necessary will automatically `:rpc`.
  """

  alias Tooru.Rpc
  require Tooru.Rpc

  use Crux.Rest

  @name Tooru.Rest

  def request(_name, request)
      when Rpc.is_none(node())
      when Rpc.is_rest(node()) do
    # Silences the dialyzer
    mod = Tooru.Rest
    mod.request(@name, request)
  end

  def request(name, request) do
    Rpc.call(Rpc.rest(), __MODULE__, :request, [name, request])
  end

  def request!(_name, request)
      when Rpc.is_none(node())
      when Rpc.is_rest(node()) do
    # Silences the dialyzer
    mod = Tooru.Rest
    mod.request!(@name, request)
  end

  def request!(name, request) do
    Rpc.call(Rpc.rest(), __MODULE__, :request!, [name, request])
  end
end
