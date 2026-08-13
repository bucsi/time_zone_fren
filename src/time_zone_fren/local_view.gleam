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

fn offset_to_minutes(offset: Duration) -> Int {
  float.round(duration.to_seconds(offset)) / seconds_per_minute
}
