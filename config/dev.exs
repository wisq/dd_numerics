use Mix.Config

if File.exists?("config/datadog.exs") do
  import_config "datadog.exs"
end

defmodule DDNumerics.Config.Colors do
  def co2_value(v) do
    cond do
      v >= 2000 -> :red
      v >= 1000 -> :orange
      true -> :green
    end
  end

  def co2_value_delta(v2, _v1) do
    co2_value(v2)
  end
end

config :dd_numerics,
  metrics: %{
    co2_current: %{
      type: :value,
      query: "co2mini.co2_ppm{*}",
      postfix: "ppm",
      color_fn: {DDNumerics.Config.Colors, :co2_value}
    },
    co2_delta_hour: %{
      type: :value_delta,
      query: "co2mini.co2_ppm{*}",
      postfix: "ppm",
      period: 3600,
      color_fn: {DDNumerics.Config.Colors, :co2_value_delta}
    },
    co2_delta_day: %{
      type: :value_delta,
      query: "co2mini.co2_ppm{*}",
      postfix: "ppm",
      period: 86400,
      color_fn: {DDNumerics.Config.Colors, :co2_value_delta}
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
