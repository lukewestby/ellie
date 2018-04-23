# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :ellie,
  ecto_repos: [Ellie.Repo],
  env: Mix.env,
  package_endpoint: System.get_env("PACKAGE_SITE")

config :ellie, Ellie.Scheduler,
  global: true,
  jobs: [
    {"*/15 * * * *", {Ellie.Search, :reload, []}},
  ]


# Configures the endpoint
config :ellie, EllieWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "+ODF8PyQMpBDb5mxA117MqkLne/bGi0PZoTl5uIHAzck2hDAJ8uGJPzark0Aolyi",
  render_errors: [view: EllieWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Ellie.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: []

# config :porcelain, :driver, Porcelain.Driver.Goon
# config :porcelain, :goon_driver_path, Path.expand("../priv/static/bin/goon", __DIR__)


config :absinthe,
  schema: EllieWeb.Graphql.Schema

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
