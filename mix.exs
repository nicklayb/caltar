defmodule Caltar.MixProject do
  use Mix.Project

  def project do
    [
      app: :caltar,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Caltar.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.7.19"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.10"},
      {:ecto_sqlite3, ">= 0.0.0"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:gettext, "~> 0.26"},
      {:jason, "~> 1.2"},
      {:credo, "~> 1.7.11", runtime: false, only: ~w(dev test)a},
      {:phoenix_live_view, "~> 1.0.4"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:bandit, "~> 1.5"},
      {:box, git: "https://github.com/nicklayb/box_ex.git", tag: "0.9.2"},
      {:ex_cldr_dates_times, "~> 2.0"},
      {:ex_cldr_numbers, "~> 2.33"},
      {:tz, "~> 0.28"},
      {:recon, "~> 2.5.6"},
      {:icalendar, git: "https://github.com/nicklayb/icalendar", tag: "1.2.2"},
      {:req, "~> 0.5.8"},
      {:polymorphic_embed, "~> 5.0.1"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind caltar", "esbuild caltar"],
      "assets.deploy": [
        "tailwind caltar --minify",
        "esbuild caltar --minify",
        "phx.digest"
      ]
    ]
  end
end
