defmodule DDNumerics.Datadog do
  alias DDNumerics.Datadog.URI, as: DDURI

  defp now do
    DateTime.utc_now()
    |> DateTime.to_unix()
  end

  def query_series({start_time, end_time}, query) do
    DDURI.datadog_uri(
      "v1/query",
      from: to_unix_time(start_time),
      to: to_unix_time(end_time),
      query: query
    )
    |> HTTPoison.get!()
    |> Map.fetch!(:body)
    |> Poison.decode!()
    |> decode_series()
  end

  defp to_unix_time(%DateTime{} = dt), do: DateTime.to_unix(dt)

  defp from_datadog_time(msecs) do
    msecs
    |> round()
    |> DateTime.from_unix!(:millisecond)
  end

  defp decode_series(%{"status" => "ok", "series" => []}), do: []

  defp decode_series(%{"status" => "ok", "series" => [%{"pointlist" => points}]}) do
    points
    |> Enum.map(fn [time, value] ->
      {from_datadog_time(time), value}
    end)
  end
end
