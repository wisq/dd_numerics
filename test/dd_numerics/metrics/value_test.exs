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

  test "extract_data/2 applies postfix" do
    points = [
      {DateTime.from_unix!(1001), 1.0}
    ]

    metric = %Value{query: "dummy", postfix: "units"}

    assert %{postfix: "units"} = Value.extract_data(points, metric)
  end

  def color_fn_1(value) do
    "color for #{value}"
  end

  test "extract_data/2 applies color function" do
    points = [
      {DateTime.from_unix!(1001), 123.45}
    ]

    metric1 = %Value{query: "dummy"}
    refute Value.extract_data(points, metric1) |> Map.has_key?(:color)

    metric2 = %Value{query: "dummy", color_fn: {__MODULE__, :color_fn_1}}
    assert %{color: "color for 123.45"} = Value.extract_data(points, metric2)
  end
end
