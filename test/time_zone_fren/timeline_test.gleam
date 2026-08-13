import gleam/int
import gleam/order
import gleam/time/duration
import gleam/time/timestamp.{type Timestamp}
import gleeunit
import time_zone_fren/timeline.{type Timeline} as tl

pub fn main() -> Nil {
  gleeunit.main()
}

const noon_2026_08_13_utc_seconds: Int = 1_786_939_200

const midnight_2026_08_13_utc_seconds: Int = 1_786_896_000

const midnight_2026_08_14_utc_seconds: Int = 1_786_982_400

const twelve_thirty_seven_2026_08_13_utc_seconds: Int = 1_786_941_420

fn reference_instant() -> Timestamp {
  timestamp.from_unix_seconds(noon_2026_08_13_utc_seconds)
}

fn reference_timeline() -> Timeline {
  tl.view(from: reference_instant())
}

fn instant(unix_seconds: Int) -> Timestamp {
  timestamp.from_unix_seconds(unix_seconds)
}

fn assert_same_instant(a: Timestamp, b: Timestamp) -> Nil {
  assert timestamp.compare(a, b) == order.Eq
  Nil
}

pub fn view_starts_12h_before_test() {
  let timeline = reference_timeline()
  assert_same_instant(timeline.start, instant(midnight_2026_08_13_utc_seconds))
  assert_same_instant(timeline.end, instant(midnight_2026_08_14_utc_seconds))
}

pub fn view_rounds_down_to_hour_test() {
  let timeline = tl.view(from: instant(twelve_thirty_seven_2026_08_13_utc_seconds))
  assert_same_instant(timeline.start, instant(midnight_2026_08_13_utc_seconds))
}

pub fn position_of_start_is_zero_test() {
  let timeline = reference_timeline()
  assert timeline |> tl.position_of(timeline.start) == 0.0
}

pub fn position_of_end_is_full_width_test() {
  let timeline = reference_timeline()
  assert timeline |> tl.position_of(timeline.end)
    == int.to_float(tl.timeline_width_px)
}

pub fn position_of_midpoint_is_half_width_test() {
  let timeline = reference_timeline()
  let half_width = int.to_float(tl.timeline_width_px) /. 2.0
  assert timeline |> tl.position_of(reference_instant()) == half_width
}

pub fn instant_at_zero_is_start_test() {
  let timeline = reference_timeline()
  assert_same_instant(timeline |> tl.instant_at(0.0), timeline.start)
}

pub fn instant_at_full_width_is_end_test() {
  let timeline = reference_timeline()
  let width = int.to_float(tl.timeline_width_px)
  assert_same_instant(timeline |> tl.instant_at(width), timeline.end)
}

pub fn instant_at_position_beyond_width_is_clamped_test() {
  let timeline = reference_timeline()
  let width = int.to_float(tl.timeline_width_px)
  assert_same_instant(timeline |> tl.instant_at(width +. 500.0), timeline.end)
}

pub fn instant_at_negative_position_is_clamped_test() {
  let timeline = reference_timeline()
  assert_same_instant(timeline |> tl.instant_at(-50.0), timeline.start)
}

pub fn snap_rounds_down_below_halfway_test() {
  let timeline = reference_timeline()
  let below_halfway = pixels_for_minutes(7.0)
  let snapped = timeline |> tl.snapped_instant_at(below_halfway)
  assert_same_instant(snapped, timeline.start)
}

pub fn snap_rounds_up_at_halfway_test() {
  let timeline = reference_timeline()
  let at_halfway = pixels_for_minutes(8.0)
  let snapped = timeline |> tl.snapped_instant_at(at_halfway)
  assert_same_instant(
    snapped,
    timestamp.add(timeline.start, duration.minutes(tl.snap_minutes)),
  )
}

pub fn snap_exact_multiple_is_unchanged_test() {
  let timeline = reference_timeline()
  let three_snap_units_in_pixels =
    pixels_for_minutes(int.to_float(tl.snap_minutes * 3))
  let snapped =
    timeline |> tl.snapped_instant_at(three_snap_units_in_pixels)
  assert_same_instant(
    snapped,
    timestamp.add(timeline.start, duration.minutes(tl.snap_minutes * 3)),
  )
}

fn pixels_for_minutes(minutes: Float) -> Float {
  minutes *. int.to_float(tl.timeline_width_px) /. 1440.0
}
