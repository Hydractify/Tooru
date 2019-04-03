use Mix.Config

import_config "../apps/*/config/config.exs"

token = "NTMyMjY3MzI0MzYzNzY3ODY5.__"
owners = [218348062828003328]

id =
  token
  |> String.split(".")
  |> List.first()
  |> Base.decode64!()
  |> String.to_integer()

config :tooru_gateway, token: token
config :tooru_rest, token: token
config :tooru_handler, id: id, owners: owners
config :tooru_lavalink, id: id

config :sentry,
  dsn: "https://__@sentry.io/__",
  environment_name: Mix.env(),
  tags: %{
    env: Mix.env()
  },
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  context_lines: 5,
  in_app_module_whitelist: [Tooru],
  json_library: Poison
