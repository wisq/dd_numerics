defmodule DDNumerics.Metrics.DeltaTest do
  use ExUnit.Case, async: true

  alias DDNumerics.Metrics.Delta

  defp dt(naive), do: DateTime.from_naive!(naive, "Etc/UTC")

  test "extract_data/3 measures points that are exactly <period> apart" do
    points = [
      {DateTime.from_unix!(1001), 93.1},
      {DateTime.from_unix!(1002), 106.1},
      {DateTime.from_unix!(1003), 103.3},
      {DateTime.from_unix!(2001), 97.7},
      {DateTime.from_unix!(2002), 93.9}
    ]

    metric = %Delta{query: "dummy", period: 1000, max_age: 20}
    now = DateTime.from_unix!(2010)

    assert %{data: %{value: diff}} = Delta.extract_data(points, metric, now)
    assert_in_delta diff, -12.2, 0.001
  end

  test "extract_data/3 interpolates between points if no exact match" do
    points = [
      {DateTime.from_unix!(1001), 93.1},
      {DateTime.from_unix!(1003), 103.3},
      {DateTime.from_unix!(2001), 97.7},
      {DateTime.from_unix!(2002), 93.9}
    ]

    metric = %Delta{query: "dummy", period: 1000, max_age: 20}
    now = DateTime.from_unix!(2010)

    assert %{data: %{value: diff}} = Delta.extract_data(points, metric, now)
    assert_in_delta diff, -4.3, 0.001
  end

  test "extract_data/3 interpolation is proportional based on time of measurements" do
    points = [
      {DateTime.from_unix!(1000), 100.0},
      {DateTime.from_unix!(1005), 105.0},
      {DateTime.from_unix!(2001), 21.1},
      {DateTime.from_unix!(2002), 205.0}
    ]

    metric = %Delta{query: "dummy", period: 1000, max_age: 20}
    now = DateTime.from_unix!(2010)

    assert %{data: %{value: 103.0}} = Delta.extract_data(points, metric, now)
  end

  test "extract_data/3 uses latter value if first is not available" do
    points = [
      {DateTime.from_unix!(1005), 105.0},
      {DateTime.from_unix!(2001), 21.1},
      {DateTime.from_unix!(2002), 205.0}
    ]

    metric = %Delta{query: "dummy", period: 1000, max_age: 20}
    now = DateTime.from_unix!(2010)

    assert %{data: %{value: 100.0}} = Delta.extract_data(points, metric, now)
  end

  test "extract_data/3 handles empty point set" do
    points = []
    metric = %Delta{query: "dummy", period: 1000, max_age: 20}
    now = DateTime.from_unix!(1)

    assert Delta.extract_data(points, metric, now) == %{}
  end

  test "extract_data/3 applies postfix" do
    points = [
      {DateTime.from_unix!(1001), 100.0},
      {DateTime.from_unix!(2001), 130.0}
    ]

    metric = %Delta{query: "dummy", period: 1000, postfix: "rupees"}
    now = DateTime.from_unix!(2010)

    assert %{postfix: "rupees"} = Delta.extract_data(points, metric, now)
  end

  def color_fn(value2, value1) do
    "color for #{value2} and #{value1}"
  end

  test "extract_data/3 applies color function" do
    points = [
      {DateTime.from_unix!(1001), 123.45},
      {DateTime.from_unix!(2001), 234.56}
    ]

    now = DateTime.from_unix!(2010)

    metric1 = %Delta{query: "dummy", period: 1000}
    refute Delta.extract_data(points, metric1, now) |> Map.has_key?(:color)

    metric2 = %Delta{query: "dummy", period: 1000, color_fn: {__MODULE__, :color_fn}}
    assert %{color: "color for 234.56 and 123.45"} = Delta.extract_data(points, metric2, now)
  end

  test "extract_data/3 handles {:daily, time} period" do
    metric = %Delta{query: "dummy", period: {:daily, "09:00"}, max_age: 300}
    now = dt(~N[2019-07-19 09:46:49.082293])

    points = [
      {dt(~N[2019-07-19 08:45:00]), 93.1},
      {dt(~N[2019-07-19 09:00:00]), 106.1},
      {dt(~N[2019-07-19 09:15:00]), 103.3},
      {dt(~N[2019-07-19 09:30:00]), 97.7},
      {dt(~N[2019-07-19 09:45:00]), 93.9}
    ]

    assert %{data: %{value: diff}} = Delta.extract_data(points, metric, now)
    assert_in_delta diff, -12.2, 0.001
  end

  test "extract_data/3 interpolates around {:daily, time} start point" do
    metric = %Delta{query: "dummy", period: {:daily, "09:00"}, max_age: 300}
    now = dt(~N[2019-07-19 09:46:49.082293])

    points = [
      {dt(~N[2019-07-19 08:45:00]), 93.1},
      {dt(~N[2019-07-19 09:15:00]), 103.3},
      {dt(~N[2019-07-19 09:30:00]), 97.7},
      {dt(~N[2019-07-19 09:45:00]), 93.9}
    ]

    assert %{data: %{value: diff}} = Delta.extract_data(points, metric, now)
    assert_in_delta diff, -4.3, 0.001
  end
end
