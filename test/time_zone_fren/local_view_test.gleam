import gleam/time/calendar
import gleam/time/timestamp
import gleeunit
import gtz
import time_zone_fren/local_view
import time_zone_fren/weekday

pub fn main() -> Nil {
  gleeunit.main()
}

const budapest_iana: String = "Europe/Budapest"

const london_iana: String = "Europe/London"

const boise_iana: String = "America/Boise"

const indianapolis_iana: String = "America/Indiana/Indianapolis"

const toronto_iana: String = "America/Toronto"

const noon_2026_08_13_utc_seconds: Int = 1_786_622_400

const noon_2026_01_15_utc_seconds: Int = 1_768_478_400

const europe_dst_end_2026_before_seconds: Int = 1_792_889_940

const europe_dst_end_2026_after_seconds: Int = 1_792_890_060

const us_east_dst_end_2026_before_seconds: Int = 1_793_512_740

const us_east_dst_end_2026_after_seconds: Int = 1_793_512_860

const boise_dst_end_2026_before_seconds: Int = 1_793_519_940

const boise_dst_end_2026_after_seconds: Int = 1_793_520_060

const late_evening_2026_08_13_utc_seconds: Int = 1_786_663_800

const early_morning_2026_08_13_utc_seconds: Int = 1_786_588_200

fn zone(iana_name: String) -> gtz.TimeZone {
  let assert Ok(z) = gtz.build(iana_name)
  z
}

fn view(unix_seconds: Int, iana_name: String) -> local_view.LocalView {
  local_view.new(timestamp.from_unix_seconds(unix_seconds), zone(iana_name))
}

pub fn budapest_summer_test() {
  let v = view(noon_2026_08_13_utc_seconds, budapest_iana)
  assert v.time.hours == 14
  assert v.time.minutes == 0
  assert v.date.year == 2026
  assert v.date.month == calendar.August
  assert v.date.day == 13
  assert v.weekday == weekday.Thursday
  assert v.offset_minutes == 120
}

pub fn london_summer_test() {
  let v = view(noon_2026_08_13_utc_seconds, london_iana)
  assert v.time.hours == 13
  assert v.time.minutes == 0
  assert v.offset_minutes == 60
}

pub fn boise_summer_test() {
  let v = view(noon_2026_08_13_utc_seconds, boise_iana)
  assert v.time.hours == 6
  assert v.offset_minutes == -360
}

pub fn indianapolis_summer_test() {
  let v = view(noon_2026_08_13_utc_seconds, indianapolis_iana)
  assert v.time.hours == 8
  assert v.offset_minutes == -240
}

pub fn montreal_summer_test() {
  let v = view(noon_2026_08_13_utc_seconds, toronto_iana)
  assert v.time.hours == 8
  assert v.offset_minutes == -240
}

pub fn budapest_winter_test() {
  let v = view(noon_2026_01_15_utc_seconds, budapest_iana)
  assert v.offset_minutes == 60
  assert v.time.hours == 13
}

pub fn london_winter_test() {
  let v = view(noon_2026_01_15_utc_seconds, london_iana)
  assert v.offset_minutes == 0
  assert v.time.hours == 12
}

pub fn boise_winter_test() {
  let v = view(noon_2026_01_15_utc_seconds, boise_iana)
  assert v.offset_minutes == -420
  assert v.time.hours == 5
}

pub fn indianapolis_winter_test() {
  let v = view(noon_2026_01_15_utc_seconds, indianapolis_iana)
  assert v.offset_minutes == -300
  assert v.time.hours == 7
}

pub fn montreal_winter_test() {
  let v = view(noon_2026_01_15_utc_seconds, toronto_iana)
  assert v.offset_minutes == -300
  assert v.time.hours == 7
}

pub fn europe_fall_back_before_test() {
  let budapest = view(europe_dst_end_2026_before_seconds, budapest_iana)
  assert budapest.offset_minutes == 120
  assert budapest.time.hours == 2
  assert budapest.time.minutes == 59
  let london = view(europe_dst_end_2026_before_seconds, london_iana)
  assert london.offset_minutes == 60
  assert london.time.hours == 1
  assert london.time.minutes == 59
}

pub fn europe_fall_back_after_test() {
  let budapest = view(europe_dst_end_2026_after_seconds, budapest_iana)
  assert budapest.offset_minutes == 60
  assert budapest.time.hours == 2
  assert budapest.time.minutes == 1
  let london = view(europe_dst_end_2026_after_seconds, london_iana)
  assert london.offset_minutes == 0
  assert london.time.hours == 1
  assert london.time.minutes == 1
}

pub fn us_fall_back_before_test() {
  let v = view(us_east_dst_end_2026_before_seconds, toronto_iana)
  assert v.offset_minutes == -240
  assert v.time.hours == 1
  assert v.time.minutes == 59
}

pub fn us_fall_back_after_test() {
  let v = view(us_east_dst_end_2026_after_seconds, toronto_iana)
  assert v.offset_minutes == -300
  assert v.time.hours == 1
  assert v.time.minutes == 1
}

pub fn indianapolis_dst_transition_test() {
  let before = view(us_east_dst_end_2026_before_seconds, indianapolis_iana)
  assert before.offset_minutes == -240
  let after = view(us_east_dst_end_2026_after_seconds, indianapolis_iana)
  assert after.offset_minutes == -300
}

pub fn boise_dst_transition_test() {
  let before = view(boise_dst_end_2026_before_seconds, boise_iana)
  assert before.offset_minutes == -360
  assert before.time.hours == 1
  assert before.time.minutes == 59
  let after = view(boise_dst_end_2026_after_seconds, boise_iana)
  assert after.offset_minutes == -420
  assert after.time.hours == 1
  assert after.time.minutes == 1
}

pub fn crosses_midnight_forward_test() {
  let budapest = view(late_evening_2026_08_13_utc_seconds, budapest_iana)
  assert budapest.date.day == 14
  assert budapest.time.hours == 1
  assert budapest.weekday == weekday.Friday

  let boise = view(late_evening_2026_08_13_utc_seconds, boise_iana)
  assert boise.date.day == 13
  assert boise.time.hours == 17
  assert boise.weekday == weekday.Thursday
}

pub fn crosses_midnight_backward_test() {
  let boise = view(early_morning_2026_08_13_utc_seconds, boise_iana)
  assert boise.date.day == 12
  assert boise.time.hours == 20
  assert boise.weekday == weekday.Wednesday
}

pub fn hour_boundary_before_rounds_to_local_hour_test() {
  let assert Ok(zone) = gtz.build(budapest_iana)
  let instant = timestamp.from_unix_seconds(1_786_624_620)
  let boundary = local_view.hour_boundary_before(instant, zone)
  let boundary_seconds = timestamp.to_unix_seconds_and_nanoseconds(boundary).0
  assert boundary_seconds == 1_786_622_400
}

pub fn hour_boundary_before_at_local_midnight_test() {
  let assert Ok(zone) = gtz.build(budapest_iana)
  let instant = timestamp.from_unix_seconds(1_786_660_200)
  let boundary = local_view.hour_boundary_before(instant, zone)
  let boundary_seconds = timestamp.to_unix_seconds_and_nanoseconds(boundary).0
  assert boundary_seconds == 1_786_658_400
}
