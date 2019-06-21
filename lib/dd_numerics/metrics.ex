defmodule DDNumerics.Metrics do
  alias __MODULE__

  @types %{
    value: Metrics.Value,
    value_delta: Metrics.ValueDelta
  }

  @metrics Application.get_env(:dd_numerics, :metrics, %{})
           |> Map.new(fn {name, %{type: type} = data} ->
             case Map.fetch(@types, type) do
               {:ok, module} ->
                 struct =
                   Map.delete(data, :type)
                   |> module.create()

                 {name, struct}

               :error ->
                 raise "Unknown metric type: #{inspect(type)}"
             end
           end)

  def get(name) when is_atom(name), do: Map.fetch(@metrics, name)

  def get(name) when is_binary(name) do
    try do
      String.to_existing_atom(name)
    rescue
      ArgumentError -> nil
    end
    |> get()
  end

  def fetch(%{__struct__: module} = metric) do
    module.fetch(metric)
  end
end
