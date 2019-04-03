defmodule Tooru.Lavalink.MixProject do
  use Mix.Project

  def project do
    [
      app: :tooru_lavalink,
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
      mod: {Tooru.Lavalink.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, ">= 0.0.0"},
      {:ex_link, git: "https://github.com/spaceeec/ex_link"},
      {:sentry, git: "https://github.com/spaceeec/sentry-elixir", branch: "fix/umbrella_path"},
      {:tooru_gateway, in_umbrella: true},
      {:tooru_rest, in_umbrella: true}
    ]
  end
end
