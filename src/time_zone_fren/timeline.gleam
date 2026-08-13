import gleam/float
import gleam/int
import gleam/time/duration
import gleam/time/timestamp.{type Timestamp}

const window_hours: Int = 24

const total_minutes: Int = 1440

@internal
pub const timeline_width_px: Int = 1000

@internal
pub const snap_minutes: Int = 15

pub type Timeline {
  Timeline(start: Timestamp, end: Timestamp)
}

pub fn view(from start: Timestamp) -> Timeline {
  Timeline(start:, end: timestamp.add(start, duration.hours(window_hours)))
}

pub fn position_of(timeline: Timeline, instant: Timestamp) -> Float {
  let elapsed_minutes = minutes_between(timeline.start, instant)
  minute_offset_to_float(elapsed_minutes)
}

pub fn instant_at(timeline: Timeline, position: Float) -> Timestamp {
  add_minutes(timeline.start, float_to_minute_offset(position))
}

pub fn snapped_instant_at(timeline: Timeline, position: Float) -> Timestamp {
  add_minutes(
    timeline.start,
    snap_to_grid(float_to_minute_offset(position), snap_minutes),
  )
}

pub fn minutes_between(from: Timestamp, to: Timestamp) -> Int {
  let #(seconds, _) =
    duration.to_seconds_and_nanoseconds(timestamp.difference(from, to))
  seconds / 60
}

fn float_to_minute_offset(position: Float) -> Int {
  let clamped = clamp_float(position, 0.0, int.to_float(timeline_width_px))
  let ratio = clamped /. int.to_float(timeline_width_px)
  float.round(ratio *. int.to_float(total_minutes))
}

fn minute_offset_to_float(minutes: Int) -> Float {
  let ratio = int.to_float(minutes) /. int.to_float(total_minutes)
  ratio *. int.to_float(timeline_width_px)
}

fn add_minutes(instant: Timestamp, minutes: Int) -> Timestamp {
  timestamp.add(instant, duration.minutes(minutes))
}

fn snap_to_grid(value: Int, grid_size: Int) -> Int {
  { value + grid_size / 2 } / grid_size * grid_size
}

fn clamp_float(value: Float, low: Float, high: Float) -> Float {
  case value <. low, value >. high {
    True, _ -> low
    _, True -> high
    _, _ -> value
  }
}
