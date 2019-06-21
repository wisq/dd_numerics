defmodule DDNumerics.Metrics.ValueDelta do
  alias DDNumerics.Datadog

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
    |> extract_window(metric.max_age, metric.period)
    |> output(metric)
  end

  defp extract_window(points, max_age, period) do
    case find_last_value(points, max_age) do
      nil ->
        nil

      {last_time, last_value} ->
        {_first_time, first_value} = find_first_value(points, last_time, period)
        {first_value, last_value}
    end
  end

  defp find_last_value(points, max_age) do
    {time, _value} = last = List.last(points)
    age = DateTime.utc_now() |> DateTime.diff(time, :second)
    if age < max_age, do: last, else: nil
  end

  defp find_first_value(points, last_time, period) do
    target_time = DateTime.add(last_time, -period)

    case find_points_around(points, target_time) do
      {nil, {time, value}} -> {time, value}
      {{time, value}, nil} -> {time, value}
      {{_, _} = p1, {_, _} = p2} -> {target_time, interpolate(p1, p2, target_time)}
    end
  end

  defp find_points_around(points, target_time) do
    (points ++ [nil])
    |> Enum.reduce_while(nil, fn
      {t2, _v2} = p2, p1 ->
        case DateTime.compare(t2, target_time) do
          :lt -> {:cont, p2}
          :gt -> {:halt, {p1, p2}}
          :eq -> {:halt, {p2, p2}}
        end

      nil, p1 ->
        {:halt, {p1, nil}}
    end)
  end

  # Same point twice: no interpolation needed.
  defp interpolate({_time, value} = point, point, _) do
    value
  end

  defp interpolate({t1, v1}, {t2, v2}, target_time) do
    period = DateTime.diff(t2, t1, :native)
    time_into = DateTime.diff(target_time, t1, :native)
    percent_into = time_into / period

    value_delta = v2 - v1
    v1 + percent_into * value_delta
  end

  defp output(nil, _metric), do: %{}

  defp output({v1, v2}, metric) do
    %{
      data: [
        %{value: v1},
        %{value: v2}
      ],
      postfix: metric.postfix
    }
  end

  defp time_range(max_age) do
    end_time = DateTime.utc_now()
    start_time = end_time |> DateTime.add(-max_age, :second)
    {start_time, end_time}
  end
end
