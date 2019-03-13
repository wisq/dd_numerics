use Mix.Config

config :dd_numerics,
  supervise: false

config :logger, level: :warn

if File.exists?("config/test_vcr.exs") do
  import_config "test_vcr.exs"
end
