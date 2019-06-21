defmodule DDNumerics.Metrics.DeltaTest do
  use ExUnit.Case, async: true

  alias DDNumerics.Metrics.Delta

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
end
