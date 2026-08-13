import gleam/time/timestamp.{type Timestamp}

pub type Weekday {
  Monday
  Tuesday
  Wednesday
  Thursday
  Friday
  Saturday
  Sunday
}

const seconds_per_day: Int = 86_400

const days_per_week: Int = 7

const unix_epoch_weekday: Weekday = Thursday

const week_from_monday: List(Weekday) = [
  Monday,
  Tuesday,
  Wednesday,
  Thursday,
  Friday,
  Saturday,
  Sunday,
]

pub fn of(instant: Timestamp) -> Weekday {
  let #(seconds, _) = timestamp.to_unix_seconds_and_nanoseconds(instant)
  let day_index = floor_div(seconds, seconds_per_day)
  weekday_after(unix_epoch_weekday, day_index)
}

pub fn is_weekend(weekday: Weekday) -> Bool {
  case weekday {
    Saturday | Sunday -> True
    _ -> False
  }
}

fn weekday_after(anchor: Weekday, days: Int) -> Weekday {
  let anchor_position = position(anchor)
  let target_position = positive_modulo(anchor_position + days, days_per_week)
  case week_from_monday |> pick_at(target_position) {
    Ok(weekday) -> weekday
    Error(_) -> anchor
  }
}

fn position(weekday: Weekday) -> Int {
  case weekday {
    Monday -> 0
    Tuesday -> 1
    Wednesday -> 2
    Thursday -> 3
    Friday -> 4
    Saturday -> 5
    Sunday -> 6
  }
}

fn pick_at(items: List(a), index: Int) -> Result(a, Nil) {
  case items, index {
    [], _ -> Error(Nil)
    [head, ..], 0 -> Ok(head)
    [_, ..rest], _ -> pick_at(rest, index - 1)
  }
}

fn floor_div(numerator: Int, denominator: Int) -> Int {
  case numerator < 0 && numerator % denominator != 0 {
    True -> numerator / denominator - 1
    False -> numerator / denominator
  }
}

fn positive_modulo(numerator: Int, denominator: Int) -> Int {
  { numerator % denominator + denominator } % denominator
}
