import Config

locale = Box.Config.get("LOCALE", default: "en")

config :caltar,
  release_name: Box.Config.get("RELEASE_NAME"),
  locale: Box.Config.get("LOCALE", default: "en")

config :caltar, Caltar.Date, timezone: Box.Config.get("TZ", default: "Etc/UTC")

config :caltar, Caltar.Repo,
  database:
    Box.Config.get!("DATABASE_PATH",
      test: Path.expand("repo/database/caltar_test.db", :code.priv_dir(:caltar)),
      dev: Path.expand("repo/database/caltar_dev.db", :code.priv_dir(:caltar))
    ),
  pool_size: Box.Config.int("POOL_SIZE", default: "5")

app_host = Box.Config.uri("APP_HOST", default: "http://localhost:4000")
port = Box.Config.int("PORT", default: "4000")

config :caltar, CaltarWeb.Endpoint,
  http: [port: port],
  url: [host: app_host.host, scheme: app_host.scheme, port: app_host.port],
  secret_key_base: Box.Config.get!("SECRET_KEY_BASE"),
  live_view: [signing_salt: Box.Config.get!("LIVE_VIEW_SALT")]

config :caltar, Caltar.Client.Geonames,
  http: [
    params: [
      username: Box.Config.get("GEONAMES_USERNAME")
    ]
  ]
