defmodule DDNumerics.Metrics.ValueDeltaTest do
  use ExUnit.Case, async: true

  alias DDNumerics.Metrics.ValueDelta

  test "extract_data/3 returns points that are exactly <period> apart" do
    points = [
      {DateTime.from_unix!(1001), 93.1},
      {DateTime.from_unix!(1002), 106.1},
      {DateTime.from_unix!(1003), 103.3},
      {DateTime.from_unix!(2001), 97.7},
      {DateTime.from_unix!(2002), 93.9}
    ]

    metric = %ValueDelta{query: "dummy", period: 1000, max_age: 20}
    now = DateTime.from_unix!(2010)

    assert %{
             data: [
               # value at 1002
               %{value: 106.1},
               # value at 2002
               %{value: 93.9}
             ]
           } = ValueDelta.extract_data(points, metric, now)
  end

  test "extract_data/3 interpolates between points if no exact match" do
    points = [
      {DateTime.from_unix!(1001), 93.1},
      {DateTime.from_unix!(1003), 103.3},
      {DateTime.from_unix!(2001), 97.7},
      {DateTime.from_unix!(2002), 93.9}
    ]

    metric = %ValueDelta{query: "dummy", period: 1000, max_age: 20}
    now = DateTime.from_unix!(2010)

    assert %{
             data: [
               # interpolated value at 1002
               %{value: v1},
               # value at 2002
               %{value: 93.9}
             ]
           } = ValueDelta.extract_data(points, metric, now)

    # average of values at 1001 and 1003
    assert_in_delta v1, 98.2, 0.001
  end

  test "extract_data/3 interpolation is proportional based on time of measurements" do
    points = [
      {DateTime.from_unix!(1000), 100.0},
      {DateTime.from_unix!(1005), 105.0},
      {DateTime.from_unix!(2001), 21.1},
      {DateTime.from_unix!(2002), 205.0}
    ]

    metric = %ValueDelta{query: "dummy", period: 1000, max_age: 20}
    now = DateTime.from_unix!(2010)

    assert %{
             data: [
               # interpolated value at 1002
               %{value: v1},
               # value at 2002
               %{value: 205.0}
             ]
           } = ValueDelta.extract_data(points, metric, now)

    # 2/5ths of the way between 100 and 105
    assert_in_delta v1, 102.0, 0.001
  end

  test "extract_data/3 uses latter value if first is not available" do
    points = [
      {DateTime.from_unix!(1005), 105.0},
      {DateTime.from_unix!(2001), 21.1},
      {DateTime.from_unix!(2002), 205.0}
    ]

    metric = %ValueDelta{query: "dummy", period: 1000, max_age: 20}
    now = DateTime.from_unix!(2010)

    assert %{
             data: [
               # value at 1005
               %{value: 105.0},
               # value at 2002
               %{value: 205.0}
             ]
           } = ValueDelta.extract_data(points, metric, now)
  end

  test "extract_data/3 handles empty point set" do
    points = []
    metric = %ValueDelta{query: "dummy", period: 1000, max_age: 20}
    now = DateTime.from_unix!(1)

    assert ValueDelta.extract_data(points, metric, now) == %{}
  end
end
