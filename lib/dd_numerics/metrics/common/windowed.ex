defmodule DDNumerics.Metrics.Common.Windowed do
  def extract_window([], _max_age, _period, _now), do: nil

  def extract_window(points, max_age, period, now) do
    case find_last_value(points, max_age, now) do
      nil ->
        nil

      {last_time, last_value} ->
        {_first_time, first_value} = find_first_value(points, last_time, period)
        {first_value, last_value}
    end
  end

  defp find_last_value(points, max_age, now) do
    {time, _value} = last = List.last(points)
    age = now |> DateTime.diff(time, :second)
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
    points
    |> Enum.reduce_while(nil, fn {t2, _v2} = p2, p1 ->
      case DateTime.compare(t2, target_time) do
        :lt -> {:cont, p2}
        :gt -> {:halt, {p1, p2}}
        :eq -> {:halt, {p2, p2}}
      end
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
end
