defmodule Tooru.RPC.MixProject do
  use Mix.Project

  def project do
    [
      app: :tooru_rpc,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:crux_rest, "~> 0.2.0"}
    ]
  end
end
