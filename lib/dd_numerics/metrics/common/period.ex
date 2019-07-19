defmodule DDNumerics.Metrics.Common.Period do
  def time_range(period, max_age, end_time \\ DateTime.utc_now()) do
    start_time = parse_period(period, max_age, end_time)
    {start_time, end_time}
  end

  defp parse_period(seconds, max_age, end_time) when is_integer(seconds) do
    secs_ago = seconds + max_age
    end_time |> DateTime.add(-secs_ago, :second)
  end

  defp parse_period({:daily, time}, max_age, end_time) do
    parse_period({:daily, time, "Etc/UTC"}, max_age, end_time)
  end

  defp parse_period({:daily, time, zone}, max_age, end_datetime) do
    zoned_datetime = end_datetime |> Timex.Timezone.convert(zone)
    current_time = zoned_datetime |> DateTime.to_time()

    wanted_time = parse_daily_time(time)

    time_in_day =
      wanted_time
      |> Time.diff(~T[00:00:00], :microsecond)
      |> Timex.Duration.from_microseconds()

    case Time.diff(current_time, wanted_time, :second) do
      secs when secs < max_age ->
        # wanted_time is either in the future (negative),
        # or within the last max_age seconds.
        # Use wanted_time from yesterday.
        Timex.shift(zoned_datetime, days: -1)

      _ ->
        # wanted_time is sufficiently far in the past.
        zoned_datetime
    end
    |> Timex.beginning_of_day()
    |> Timex.add(time_in_day)
    |> Timex.Timezone.convert("Etc/UTC")
  end

  defp parse_daily_time(time) when is_binary(time) do
    String.split(time, ":", parts: 3)
    |> Enum.map(&String.to_integer/1)
    |> parse_daily_time_parts()
  end

  defp parse_daily_time(hour) when is_integer(hour) do
    parse_daily_time_parts([hour, 0, 0])
  end

  defp parse_daily_time_parts([hour, minute, second]) do
    {:ok, time} = Time.new(hour, minute, second)
    time
  end

  defp parse_daily_time_parts([hour, minute]) do
    parse_daily_time_parts([hour, minute, 0])
  end
end
