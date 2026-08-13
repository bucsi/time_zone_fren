import gleeunit
import time_zone_fren/format

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn offset_positive_test() {
  assert format.offset(60) == "UTC+1"
  assert format.offset(120) == "UTC+2"
  assert format.offset(0) == "UTC+0"
}

pub fn offset_negative_test() {
  assert format.offset(-300) == "UTC-5"
  assert format.offset(-420) == "UTC-7"
}

pub fn offset_half_hour_test() {
  assert format.offset(330) == "UTC+5:30"
  assert format.offset(-210) == "UTC-3:30"
}
