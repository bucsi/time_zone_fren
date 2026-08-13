import gleam/float
import gleam/time/calendar.{type Date, type TimeOfDay}
import gleam/time/duration.{type Duration}
import gleam/time/timestamp.{type Timestamp}
import gtz.{type TimeZone}
import time_zone_fren/weekday.{type Weekday}

pub type LocalView {
  LocalView(date: Date, time: TimeOfDay, weekday: Weekday, offset_minutes: Int)
}

const seconds_per_minute: Int = 60

const seconds_per_hour: Int = 3600

pub fn new(instant: Timestamp, zone: TimeZone) -> LocalView {
  let #(date, time, offset) = gtz.to_calendar(instant, zone)
  let local_instant = timestamp.add(instant, offset)
  LocalView(
    date:,
    time:,
    weekday: weekday.of(local_instant),
    offset_minutes: offset_to_minutes(offset),
  )
}

/// The most recent instant that coincides with the top of a wall-clock hour
/// in the given zone. Approximate around DST transitions (uses the zone's
/// offset at `instant`, not at the rounded boundary — off by ≤1h twice a year
/// within a small window near the transition).
pub fn hour_boundary_before(
  instant: Timestamp,
  zone: TimeZone,
) -> Timestamp {
  let #(_, _, offset) = gtz.to_calendar(instant, zone)
  let #(seconds, _) = timestamp.to_unix_seconds_and_nanoseconds(instant)
  let offset_seconds = float.round(duration.to_seconds(offset))
  let local_seconds = seconds + offset_seconds
  let rounded_local_seconds =
    local_seconds / seconds_per_hour * seconds_per_hour
  timestamp.from_unix_seconds(rounded_local_seconds - offset_seconds)
}

fn offset_to_minutes(offset: Duration) -> Int {
  float.round(duration.to_seconds(offset)) / seconds_per_minute
}
