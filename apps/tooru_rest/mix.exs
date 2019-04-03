defmodule Tooru.Rest.MixProject do
  use Mix.Project

  def project do
    [
      app: :tooru_rest,
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
      mod: {Tooru.Rest.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:crux_rest, "~> 0.2.0"},
      {:sentry, git: "https://github.com/spaceeec/sentry-elixir", branch: "fix/umbrella_path"}
    ]
  end
end
