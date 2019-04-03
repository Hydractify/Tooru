defmodule Tooru.Cache.MixProject do
  use Mix.Project

  def project do
    [
      app: :tooru_cache,
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

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Tooru.Cache.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:crux_base, git: "https://github.com/spaceeec/crux_base.git"},
      {:crux_cache, "~> 0.2.0"},
      {:tooru_gateway, in_umbrella: true}
    ]
  end
end
