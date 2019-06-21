defmodule DDNumerics.DatadogTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias DDNumerics.Datadog

  setup do
    [:datadog_api_key, :datadog_application_key, :datadog_host]
    |> Enum.map(fn target ->
      source = :"vcr_#{target}"
      value = Application.get_env(:dd_numerics, source, "not set")
      Application.put_env(:dd_numerics, target, value)

      ExVCR.Config.filter_sensitive_data(
        Regex.escape(value),
        source |> Atom.to_string() |> String.upcase()
      )

      {target, value}
    end)
  end

  test "query_series/2 queries datapoints from series", %{datadog_host: host} do
    data =
      use_cassette "query_cpu_idle" do
        time_window(600)
        |> Datadog.query_series("system.cpu.idle{host:#{host}}")
      end

    # Ensure that our concept of "now" changes
    # based on when this test was recorded.
    now =
      extract_cassette_date("query_cpu_idle")
      |> Timex.to_unix()

    {earliest_dt, earliest_value} = List.first(data)
    {latest_dt, latest_value} = List.last(data)
    assert is_float(earliest_value)
    assert is_float(latest_value)

    earliest = Timex.to_unix(earliest_dt)
    latest = Timex.to_unix(latest_dt)

    # can fail if NTP sync badly off
    assert latest < now
    # within one minute
    assert_in_delta latest, now, 60.0
    # within one minute of the start of the window
    assert_in_delta earliest, now - 600, 60.0
  end

  defp extract_cassette_date(name) do
    File.read!("fixture/vcr_cassettes/#{name}.json")
    |> Poison.decode!()
    |> List.first()
    |> Map.fetch!("response")
    |> Map.fetch!("headers")
    |> Map.fetch!("Date")
    |> Timex.parse!("{RFC1123}")
  end

  defp time_window(seconds) do
    end_time = DateTime.utc_now()
    start_time = DateTime.add(end_time, -seconds, :second)
    {start_time, end_time}
  end

  test "query_series/2 handles no datapoints in window", %{datadog_host: host} do
    latest =
      use_cassette "query_nonexistent" do
        time_window(600)
        |> Datadog.query_series("test.nonexistent{host:#{host}}")
      end

    assert latest == []
  end
end
