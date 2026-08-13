import gleam/int
import gleam/string
import gleam/time/calendar.{type Date, type Month, type TimeOfDay}
import time_zone_fren/weekday.{type Weekday}

const minutes_per_hour: Int = 60

const time_field_width: Int = 2

const time_field_padding: String = "0"

pub fn offset(minutes: Int) -> String {
  let magnitude = int.absolute_value(minutes)
  "UTC" <> offset_sign(minutes) <> offset_hours(magnitude) <> offset_fraction(magnitude)
}

pub fn time_of_day(time: TimeOfDay) -> String {
  pad_time_field(time.hours) <> ":" <> pad_time_field(time.minutes)
}

pub fn short_date(date: Date, weekday: Weekday) -> String {
  short_weekday(weekday)
  <> " "
  <> int.to_string(date.day)
  <> " "
  <> short_month(date.month)
}

pub fn short_weekday(weekday: Weekday) -> String {
  case weekday {
    weekday.Monday -> "Mon"
    weekday.Tuesday -> "Tue"
    weekday.Wednesday -> "Wed"
    weekday.Thursday -> "Thu"
    weekday.Friday -> "Fri"
    weekday.Saturday -> "Sat"
    weekday.Sunday -> "Sun"
  }
}

pub fn short_month(month: Month) -> String {
  case month {
    calendar.January -> "Jan"
    calendar.February -> "Feb"
    calendar.March -> "Mar"
    calendar.April -> "Apr"
    calendar.May -> "May"
    calendar.June -> "Jun"
    calendar.July -> "Jul"
    calendar.August -> "Aug"
    calendar.September -> "Sep"
    calendar.October -> "Oct"
    calendar.November -> "Nov"
    calendar.December -> "Dec"
  }
}

fn offset_sign(minutes: Int) -> String {
  case minutes < 0 {
    True -> "-"
    False -> "+"
  }
}

fn offset_hours(magnitude_minutes: Int) -> String {
  int.to_string(magnitude_minutes / minutes_per_hour)
}

fn offset_fraction(magnitude_minutes: Int) -> String {
  case magnitude_minutes % minutes_per_hour {
    0 -> ""
    remainder -> ":" <> pad_time_field(remainder)
  }
}

fn pad_time_field(value: Int) -> String {
  int.to_string(value) |> string.pad_start(time_field_width, time_field_padding)
}
