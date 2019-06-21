defmodule DDNumerics.Metrics.Value do
  alias DDNumerics.Datadog

  @enforce_keys [:query]
  defstruct(
    query: nil,
    max_age: 300,
    postfix: ""
  )

  def create(%{} = data), do: struct!(__MODULE__, data)

  def fetch(%__MODULE__{} = metric) do
    time_range(metric.max_age)
    |> Datadog.query_series(metric.query)
    |> extract_data(metric)
  end

  def extract_data(points, metric) do
    points
    |> List.last()
    |> output(metric)
  end

  defp output(nil, _metric), do: %{}

  defp output({_time, value}, metric) do
    %{
      data: %{value: value},
      postfix: metric.postfix
    }
  end

  defp time_range(max_age) do
    end_time = DateTime.utc_now()
    start_time = end_time |> DateTime.add(-max_age, :second)
    {start_time, end_time}
  end
end
