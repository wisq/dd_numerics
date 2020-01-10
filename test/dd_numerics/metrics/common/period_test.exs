defmodule DDNumerics.Metrics.Common.PeriodTest do
  use ExUnit.Case, async: true

  alias DDNumerics.Metrics.Common.Period

  defp dt(naive), do: DateTime.from_naive!(naive, "Etc/UTC")

  test "time_range/3 with integer uses seconds+max_age ago" do
    now = dt(~N[2019-07-19 04:26:49.082293])

    assert Period.time_range(3600, 300, now) == {
             dt(~N[2019-07-19 03:21:49.082293]),
             now
           }
  end

  test "time_range/3 with {:daily, time} rewinds today to `time`" do
    now = dt(~N[2019-07-19 12:34:37.585025])

    assert Period.time_range({:daily, "06:16"}, 900, now) == {
             dt(~N[2019-07-19 06:16:00]),
             now
           }
  end

  test "time_range/3 with {:daily, time} rewinds to yesterday if `time` is in the future" do
    now = dt(~N[2019-07-19 05:34:37.585025])

    assert Period.time_range({:daily, "06:16"}, 900, now) == {
             dt(~N[2019-07-18 06:16:00]),
             now
           }
  end

  test "time_range/3 with {:daily, time} rewinds to yesterday if `time` is within `max_age` seconds ago" do
    now = dt(~N[2019-07-19 06:17:37.585025])

    assert Period.time_range({:daily, "06:16"}, 60, now) == {
             dt(~N[2019-07-19 06:16:00]),
             now
           }

    assert Period.time_range({:daily, "06:16"}, 120, now) == {
             dt(~N[2019-07-18 06:16:00]),
             now
           }
  end

  test "time_range/3 with {:daily, time, zone} operates in TZ `zone`" do
    winter = dt(~N[2019-01-19 16:38:48.907577])

    # Standard time, in past:
    assert Period.time_range({:daily, "09:23", "America/Toronto"}, 1800, winter) == {
             dt(~N[2019-01-19 14:23:00]),
             winter
           }

    # Standard time, within max_age:
    assert Period.time_range({:daily, "12:23", "America/Toronto"}, 1800, winter) == {
             dt(~N[2019-01-18 17:23:00]),
             winter
           }
  end

  test "time_range/3 with {:daily, time, zone} handles daylight savings" do
    summer = dt(~N[2019-07-19 16:38:48.907577])

    # Summer time, in past:
    assert Period.time_range({:daily, "09:23", "America/Toronto"}, 1800, summer) == {
             dt(~N[2019-07-19 13:23:00]),
             summer
           }

    # Summer time, within max_age:
    assert Period.time_range({:daily, "12:23", "America/Toronto"}, 1800, summer) == {
             dt(~N[2019-07-18 16:23:00]),
             summer
           }
  end

  test "time_range/3 with {:daily, time, zone} works correctly when shifting into DST" do
    on_edt_day = dt(~N[2019-03-10 16:38:48.907577])

    # Today, 09:23 EDT (-4) = 13:23 UTC
    assert Period.time_range({:daily, "09:23", "America/Toronto"}, 1800, on_edt_day) == {
             dt(~N[2019-03-10 13:23:00]),
             on_edt_day
           }

    # Today, 00:23 EST (-5) = 05:23 UTC
    assert Period.time_range({:daily, "00:23", "America/Toronto"}, 1800, on_edt_day) == {
             dt(~N[2019-03-10 05:23:00]),
             on_edt_day
           }

    # Yesterday, 12:23 EST (-5) = 17:23 UTC
    assert Period.time_range({:daily, "12:23", "America/Toronto"}, 1800, on_edt_day) == {
             dt(~N[2019-03-09 17:23:00]),
             on_edt_day
           }
  end

  test "time_range/3 with {:daily, time, zone} works correctly when shifting out of DST" do
    on_est_day = dt(~N[2019-11-03 16:38:48.907577])

    # Today, 09:23 EST (-5) = 14:23 UTC
    assert Period.time_range({:daily, "09:23", "America/Toronto"}, 1800, on_est_day) == {
             dt(~N[2019-11-03 14:23:00]),
             on_est_day
           }

    # Today, 00:23 EDT (-4) = 04:23 UTC
    assert Period.time_range({:daily, "00:23", "America/Toronto"}, 1800, on_est_day) == {
             dt(~N[2019-11-03 04:23:00]),
             on_est_day
           }

    # Today, 01:23 EDT (-4) = 05:23 UTC
    # This is during the "lost hour" of daylight savings.
    # (There's currently no way to specify 01:23 EST.)
    assert Period.time_range({:daily, "01:23", "America/Toronto"}, 1800, on_est_day) == {
             dt(~N[2019-11-03 05:23:00]),
             on_est_day
           }

    # Today, 02:23 EST (-5) = 07:23 UTC
    assert Period.time_range({:daily, "02:23", "America/Toronto"}, 1800, on_est_day) == {
             dt(~N[2019-11-03 07:23:00]),
             on_est_day
           }

    # Yesterday, 12:23 EDT (-4) = 16:23 UTC
    assert Period.time_range({:daily, "12:23", "America/Toronto"}, 1800, on_est_day) == {
             dt(~N[2019-11-02 16:23:00]),
             on_est_day
           }
  end

  test "time_range/3 with {:daily, time, zone} doesn't skip days when working late on DST day" do
    # The last second of 2019-03-10 EDT (-4):
    late_on_edt_day = dt(~N[2019-03-11 03:59:59.123123])

    # If you naively take 2019-03-11 00:00:00 (EST) and add 23h30m to it,
    # you'll actually get 2019-03-12 00:30:00 (EDT) because you lost
    # an hour.
    #
    # `Timex.shift` seems to be safe here, but this checks for would-be regressions.
    assert Period.time_range({:daily, "23:30", "America/Toronto"}, 300, late_on_edt_day) == {
             dt(~N[2019-03-11 03:30:00]),
             late_on_edt_day
           }
  end

  test "time_range/3 with {:weekly, day, time} rewinds today to `time`" do
    now = dt(~N[2020-01-10 09:37:33.881594Z])

    assert Period.time_range({:weekly, :tuesday, "03:21"}, 900, now) == {
             dt(~N[2020-01-07 03:21:00]),
             now
           }
  end

  test "time_range/3 with {:weekly, day, time} uses last week if `day` is later in the week" do
    now = dt(~N[2020-01-10 09:37:33.881594Z])

    assert Period.time_range({:weekly, :sunday, "03:21"}, 900, now) == {
             dt(~N[2020-01-05 03:21:00]),
             now
           }
  end

  test "time_range/3 with {:weekly, day, time} uses this week if `day` is today and `time` is long enough ago" do
    now = dt(~N[2020-01-10 09:37:33.881594Z])

    assert Period.time_range({:weekly, :friday, "03:21"}, 900, now) == {
             dt(~N[2020-01-10 03:21:00]),
             now
           }
  end

  test "time_range/3 with {:weekly, day, time} uses last week if `day` is today but `time` is too recent" do
    now = dt(~N[2020-01-10 09:37:33.881594Z])

    assert Period.time_range({:weekly, :friday, "09:35"}, 900, now) == {
             dt(~N[2020-01-03 09:35:00]),
             now
           }
  end

  test "time_range/3 with {:weekly, day, time, zone} operates in TZ `zone`" do
    winter = dt(~N[2019-01-19 16:38:48.907577])

    # Standard time, earlier today:
    assert Period.time_range({:weekly, :sat, "09:23", "America/Toronto"}, 1800, winter) == {
             dt(~N[2019-01-19 14:23:00]),
             winter
           }

    # Standard time, within max_age:
    assert Period.time_range({:weekly, :sat, "12:23", "America/Toronto"}, 1800, winter) == {
             dt(~N[2019-01-12 17:23:00]),
             winter
           }

    # Standard time, later in the week:
    assert Period.time_range({:weekly, :sun, "12:23", "America/Toronto"}, 1800, winter) == {
             dt(~N[2019-01-13 17:23:00]),
             winter
           }
  end

  test "time_range/3 with {:weekly, day, time, zone} handles daylight savings" do
    summer = dt(~N[2019-07-19 16:38:48.907577])

    # Summer time, earlier in the week:
    assert Period.time_range({:weekly, :wed, "09:23", "America/Toronto"}, 1800, summer) == {
             dt(~N[2019-07-17 13:23:00]),
             summer
           }

    # Summer time, earlier today:
    assert Period.time_range({:weekly, :fri, "09:23", "America/Toronto"}, 1800, summer) == {
             dt(~N[2019-07-19 13:23:00]),
             summer
           }

    # Summer time, within max_age:
    assert Period.time_range({:weekly, :fri, "12:23", "America/Toronto"}, 1800, summer) == {
             dt(~N[2019-07-12 16:23:00]),
             summer
           }
  end

  test "time_range/3 with {:weekly, day, time, zone} handles shifting into DST" do
    # Tuesday after EDT switchover:
    after_edt = dt(~N[2019-03-12 16:38:48.907577])

    # Last Saturday at 09:23 EST (-4) = 14:23 UTC
    assert Period.time_range({:weekly, :sat, "09:23", "America/Toronto"}, 1800, after_edt) == {
             dt(~N[2019-03-09 14:23:00]),
             after_edt
           }

    # Last Sunday (EDT day) at 09:23 EDT (-4) = 13:23 UTC
    assert Period.time_range({:weekly, :sun, "09:23", "America/Toronto"}, 1800, after_edt) == {
             dt(~N[2019-03-10 13:23:00]),
             after_edt
           }

    # Last Sunday (EDT day) at 00:23 EST (-5) = 05:23 UTC
    assert Period.time_range({:weekly, :sun, "00:23", "America/Toronto"}, 1800, after_edt) == {
             dt(~N[2019-03-10 05:23:00]),
             after_edt
           }
  end

  test "time_range/3 with {:weekly, day, time, zone} handles shifting out of DST" do
    # Friday after EST switchover:
    after_est = dt(~N[2019-11-08 16:38:48.907577])

    # Last Saturday at 09:23 EDT (-4) = 13:23 UTC
    assert Period.time_range({:weekly, :sat, "09:23", "America/Toronto"}, 1800, after_est) == {
             dt(~N[2019-11-02 13:23:00]),
             after_est
           }

    # Last Sunday (EST day) at 09:23 EST (-4) = 14:23 UTC
    assert Period.time_range({:weekly, :sun, "09:23", "America/Toronto"}, 1800, after_est) == {
             dt(~N[2019-11-03 14:23:00]),
             after_est
           }

    # Last Sunday (EST day) at 00:23 EDT (-4) = 04:23 UTC
    assert Period.time_range({:weekly, :sun, "00:23", "America/Toronto"}, 1800, after_est) == {
             dt(~N[2019-11-03 04:23:00]),
             after_est
           }

    # Last Sunday (EST day) at 01:23 EDT (-4) = 05:23 UTC
    # This is during the "lost hour" of daylight savings.
    # (There's currently no way to specify 01:23 EST.)
    assert Period.time_range({:weekly, :sun, "01:23", "America/Toronto"}, 1800, after_est) == {
             dt(~N[2019-11-03 05:23:00]),
             after_est
           }

    # Last Sunday (EST day) at 02:23 EST (-5) = 07:23 UTC
    assert Period.time_range({:weekly, :sun, "02:23", "America/Toronto"}, 1800, after_est) == {
             dt(~N[2019-11-03 07:23:00]),
             after_est
           }
  end
end
