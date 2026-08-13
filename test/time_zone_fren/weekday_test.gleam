import gleam/time/timestamp
import gleeunit
import time_zone_fren/weekday

pub fn main() -> Nil {
  gleeunit.main()
}

const midnight_2026_08_13_utc_seconds: Int = 1_786_579_200

const midnight_2026_01_01_utc_seconds: Int = 1_767_225_600

const leap_day_2000_utc_seconds: Int = 951_782_400

const last_day_of_1999_utc_seconds: Int = 946_598_400

const day_before_epoch_utc_seconds: Int = -86_400

pub fn thursday_2026_08_13_test() {
  assert weekday.of(timestamp.from_unix_seconds(midnight_2026_08_13_utc_seconds))
    == weekday.Thursday
}

pub fn thursday_2026_01_01_test() {
  assert weekday.of(timestamp.from_unix_seconds(midnight_2026_01_01_utc_seconds))
    == weekday.Thursday
}

pub fn leap_day_2000_is_tuesday_test() {
  assert weekday.of(timestamp.from_unix_seconds(leap_day_2000_utc_seconds))
    == weekday.Tuesday
}

pub fn last_day_of_1999_is_friday_test() {
  assert weekday.of(timestamp.from_unix_seconds(last_day_of_1999_utc_seconds))
    == weekday.Friday
}

pub fn day_before_epoch_is_wednesday_test() {
  assert weekday.of(timestamp.from_unix_seconds(day_before_epoch_utc_seconds))
    == weekday.Wednesday
}

pub fn is_weekend_test() {
  assert weekday.is_weekend(weekday.Saturday)
  assert weekday.is_weekend(weekday.Sunday)
  assert !weekday.is_weekend(weekday.Monday)
  assert !weekday.is_weekend(weekday.Friday)
}
