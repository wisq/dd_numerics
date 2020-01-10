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
    zoned_end = end_datetime |> Timex.Timezone.convert(zone)
    wanted_time = parse_time_of_day(time)

    case is_too_recent?(zoned_end, wanted_time, max_age) do
      true -> Timex.shift(zoned_end, days: -1)
      false -> zoned_end
    end
    |> set_time_of_day(wanted_time)
    |> Timex.Timezone.convert("Etc/UTC")
  end

  defp parse_period({:weekly, day, time}, max_age, end_time) do
    parse_period({:weekly, day, time, "Etc/UTC"}, max_age, end_time)
  end

  defp parse_period({:weekly, day, time, zone}, max_age, end_datetime) do
    zoned_end = end_datetime |> Timex.Timezone.convert(zone)
    wanted_day = parse_day_of_week(day)
    wanted_time = parse_time_of_day(time)

    case is_too_recent?(zoned_end, wanted_time, max_age) do
      true -> Timex.shift(zoned_end, days: -1)
      false -> zoned_end
    end
    |> rewind_to_day_of_week(wanted_day)
    |> set_time_of_day(wanted_time)
    |> Timex.Timezone.convert("Etc/UTC")
  end

  defp rewind_to_day_of_week(datetime, wanted_day) do
    current_day = datetime |> DateTime.to_date() |> Date.day_of_week()
    days_ago = rem(current_day + 7 - wanted_day, 7)
    Timex.shift(datetime, days: -days_ago)
  end

  defp is_too_recent?(datetime, cutoff_time, max_age) do
    Time.diff(datetime, cutoff_time, :second) < max_age
  end

  defp set_time_of_day(datetime, wanted_time) do
    datetime
    |> Timex.beginning_of_day()
    |> Timex.shift(
      hours: wanted_time.hour,
      minutes: wanted_time.minute,
      seconds: wanted_time.second
    )
    |> Timex.set(microsecond: wanted_time.microsecond)
  end

  defp parse_time_of_day(time) when is_binary(time) do
    String.split(time, ":", parts: 3)
    |> Enum.map(&String.to_integer/1)
    |> parse_tod_parts()
  end

  defp parse_time_of_day(hour) when is_integer(hour) do
    parse_tod_parts([hour, 0, 0])
  end

  defp parse_tod_parts([hour, minute]) do
    parse_tod_parts([hour, minute, 0])
  end

  defp parse_tod_parts([hour, minute, second]) do
    {:ok, time} = Time.new(hour, minute, second)
    time
  end

  defp parse_day_of_week(:monday), do: 1
  defp parse_day_of_week(:tuesday), do: 2
  defp parse_day_of_week(:wednesday), do: 3
  defp parse_day_of_week(:thursday), do: 4
  defp parse_day_of_week(:friday), do: 5
  defp parse_day_of_week(:saturday), do: 6
  defp parse_day_of_week(:sunday), do: 7
  defp parse_day_of_week(:mon), do: 1
  defp parse_day_of_week(:tue), do: 2
  defp parse_day_of_week(:wed), do: 3
  defp parse_day_of_week(:thu), do: 4
  defp parse_day_of_week(:fri), do: 5
  defp parse_day_of_week(:sat), do: 6
  defp parse_day_of_week(:sun), do: 7
  defp parse_day_of_week(num) when is_integer(num) and num in 1..7, do: num
end
