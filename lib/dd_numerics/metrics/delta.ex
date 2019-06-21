defmodule DDNumerics.Metrics.Delta do
  alias DDNumerics.Datadog

  import DDNumerics.Metrics.Common.Windowed

  @enforce_keys [:query, :period]
  defstruct(
    query: nil,
    period: nil,
    max_age: 300,
    postfix: ""
  )

  def create(%{} = data), do: struct!(__MODULE__, data)

  def fetch(%__MODULE__{} = metric) do
    time_range(metric.max_age + metric.period)
    |> Datadog.query_series(metric.query)
    |> extract_data(metric)
  end

  def extract_data(points, metric, now \\ DateTime.utc_now()) do
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
  end

  defp time_range(max_age) do
    end_time = DateTime.utc_now()
    start_time = end_time |> DateTime.add(-max_age, :second)
    {start_time, end_time}
  end
end
