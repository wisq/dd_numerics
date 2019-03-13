use Mix.Config

# To configure dd_numerics to log to your Datadog account,
# you can copy this file to config/datadog.exs and fill
# in your real Datadog credentials.
#
# Alternatively, you can supply your credentials via
# environment variables.  See the `README.md` for details.

config :dd_numerics,
  datadog_api_key: "api key",
  datadog_application_key: "application key"
