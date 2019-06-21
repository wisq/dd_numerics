defmodule DDNumerics.Metrics.ValueTest do
  use ExUnit.Case, async: true

  alias DDNumerics.Metrics.Value

  test "extract_data/2 uses last point" do
    points = [
      {DateTime.from_unix!(1001), 93.1},
      {DateTime.from_unix!(1002), 106.1},
      {DateTime.from_unix!(1003), 103.3}
    ]

    metric = %Value{query: "dummy"}

    assert %{data: %{value: 103.3}} = Value.extract_data(points, metric)
  end

  test "extract_data/2 handles no points" do
    points = []
    metric = %Value{query: "dummy"}

    assert Value.extract_data(points, metric) == %{}
  end
end
