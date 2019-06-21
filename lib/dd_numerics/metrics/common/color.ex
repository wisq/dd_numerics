defmodule DDNumerics.Metrics.Common.Color do
  def add_color_fn(data, nil, _args), do: data

  def add_color_fn(data, {module, function}, args) do
    Map.put(data, :color, apply(module, function, args))
  end
end
