defmodule DDNumerics.Metrics.Common.PeriodTest do
  use ExUnit.Case, async: true

  alias DDNumerics.Metrics.Common.Period

  defp dt(naive), do: DateTime.from_naive!(naive, "Etc/UTC")

  test "time_range/3 with integer uses seconds+max_age ago" do
    now = dt(~N[2019-07-19 04:26:49.082293])

    assert Period.time_range(3600, 300, now) == {
             dt(~N[2019-07-19 03:21:49.082293]),
             dt(~N[2019-07-19 04:26:49.082293])
           }
  end

  test "time_range/3 with {:daily, time} rewinds today to `time`" do
    now = dt(~N[2019-07-19 12:34:37.585025])

    assert Period.time_range({:daily, "06:16"}, 900, now) == {
             dt(~N[2019-07-19 06:16:00]),
             dt(~N[2019-07-19 12:34:37.585025])
           }
  end

  test "time_range/3 with {:daily, time} rewinds to yesterday if `time` is in the future" do
    now = dt(~N[2019-07-19 05:34:37.585025])

    assert Period.time_range({:daily, "06:16"}, 900, now) == {
             dt(~N[2019-07-18 06:16:00]),
             dt(~N[2019-07-19 05:34:37.585025])
           }
  end

  test "time_range/3 with {:daily, time} rewinds to yesterday if `time` is within `max_age` seconds ago" do
    now = dt(~N[2019-07-19 06:17:37.585025])

    assert Period.time_range({:daily, "06:16"}, 60, now) == {
             dt(~N[2019-07-19 06:16:00]),
             dt(~N[2019-07-19 06:17:37.585025])
           }

    assert Period.time_range({:daily, "06:16"}, 120, now) == {
             dt(~N[2019-07-18 06:16:00]),
             dt(~N[2019-07-19 06:17:37.585025])
           }
  end

  test "time_range/3 with {:daily, time, zone} operates in TZ `zone`" do
    summer = dt(~N[2019-07-19 16:38:48.907577])
    winter = dt(~N[2019-01-19 16:38:48.907577])

    # Summer time, in past:
    assert Period.time_range({:daily, "09:23", "America/Toronto"}, 1800, summer) == {
             dt(~N[2019-07-19 13:23:00]),
             dt(~N[2019-07-19 16:38:48.907577])
           }

    # Summer time, within max_age:
    assert Period.time_range({:daily, "12:23", "America/Toronto"}, 1800, summer) == {
             dt(~N[2019-07-18 16:23:00]),
             dt(~N[2019-07-19 16:38:48.907577])
           }

    # Winter time, in past:
    assert Period.time_range({:daily, "09:23", "America/Toronto"}, 1800, winter) == {
             dt(~N[2019-01-19 14:23:00]),
             dt(~N[2019-01-19 16:38:48.907577])
           }

    # Winter time, in future:
    assert Period.time_range({:daily, "12:23", "America/Toronto"}, 1800, winter) == {
             dt(~N[2019-01-18 17:23:00]),
             dt(~N[2019-01-19 16:38:48.907577])
           }
  end
end
