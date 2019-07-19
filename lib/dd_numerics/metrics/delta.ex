defmodule DDNumerics.Metrics.Delta do
  alias DDNumerics.Datadog

  import DDNumerics.Metrics.Common.Windowed
  import DDNumerics.Metrics.Common.Color
  import DDNumerics.Metrics.Common.Period

  @enforce_keys [:query, :period]
  defstruct(
    query: nil,
    period: nil,
    max_age: 300,
    postfix: "",
    color_fn: nil
  )

  def create(%{} = data), do: struct!(__MODULE__, data)

  def fetch(%__MODULE__{} = metric) do
    now = DateTime.utc_now()

    time_range(metric.period, metric.max_age, now)
    |> Datadog.query_series(metric.query)
    |> extract_data(metric, now)
  end

  def extract_data(points, metric, now) do
    points
    |> extract_window(metric.max_age, metric.period, now)
    |> output(metric)
  end

  defp output(nil, _metric), do: %{}

  defp output({v1, v2}, metric) do
    %{
      data: %{value: v2 - v1},
      postfix: metric.postfix
    }
    |> add_color_fn(metric.color_fn, [v2, v1])
  end
end
