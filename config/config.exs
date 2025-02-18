import Config

config :caltar,
  environment: config_env(),
  ecto_repos: [Caltar.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true],
  main_calendar: Caltar.Calendar.Main

config :caltar, CaltarWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: CaltarWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Caltar.PubSub

config :caltar, CaltarWeb.Gettext, default_locale: "en"

config :ex_cldr, default_backend: Caltar.Cldr, default_locale: "en"

config :elixir, :time_zone_database, Tz.TimeZoneDatabase

config :esbuild,
  version: "0.17.11",
  caltar: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "3.4.3",
  caltar: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
