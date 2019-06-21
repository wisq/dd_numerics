use Mix.Config

if File.exists?("config/datadog.exs") do
  import_config "datadog.exs"
end

config :dd_numerics,
  metrics: %{
    co2_current: %{
      type: :value,
      query: "co2mini.co2_ppm{*}",
      postfix: "ppm"
    },
    co2_delta_hour: %{
      type: :value_delta,
      query: "co2mini.co2_ppm{*}",
      postfix: "ppm",
      period: 3600
    },
    co2_delta_day: %{
      type: :value_delta,
      query: "co2mini.co2_ppm{*}",
      postfix: "ppm",
      period: 86400
    },
    nonexistent_value: %{
      type: :value,
      query: "dummy.nonexistent{*}",
      postfix: "ppm"
    },
    nonexistent_value_delta: %{
      type: :value_delta,
      query: "dummy.nonexistent{*}",
      postfix: "ppm",
      period: 3600
    }
  }
