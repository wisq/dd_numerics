use Mix.Config

if File.exists?("config/datadog.exs") do
  import_config "datadog.exs"
end

config :dd_numerics,
  metrics: %{
    co2: %{
      type: :number,
      query: "co2mini.co2_ppm{*}"
    }
  }
