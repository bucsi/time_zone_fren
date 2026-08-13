import gleam/dynamic/decode
import gleam/float
import gleam/int
import gleam/list
import gleam/time/timestamp.{type Timestamp}
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import plinth/javascript/global
import time_zone_fren/format
import time_zone_fren/local_view.{type LocalView}
import time_zone_fren/location.{type Location}
import time_zone_fren/timeline.{type Timeline} as tl
import time_zone_fren/weekday

const tick_interval_ms: Int = 60_000

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

pub type Model {
  Model(locations: List(Location), selected: Timestamp, now: Timestamp)
}

pub type Msg {
  SelectAt(x: Float)
  GoToNow
  Tick(now: Timestamp)
}

fn init(_flags: Nil) -> #(Model, Effect(Msg)) {
  let now = timestamp.system_time()
  let model = Model(locations: location.defaults(), selected: now, now:)
  #(model, tick_every_minute())
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    SelectAt(x) -> {
      let timeline = tl.view(from: model.selected)
      let snapped = timeline |> tl.snapped_instant_at(x)
      #(Model(..model, selected: snapped), effect.none())
    }
    GoToNow -> #(Model(..model, selected: model.now), effect.none())
    Tick(new_now) -> #(Model(..model, now: new_now), effect.none())
  }
}

fn tick_every_minute() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let _ =
      global.set_interval(tick_interval_ms, fn() {
        dispatch(Tick(timestamp.system_time()))
      })
    Nil
  })
}

fn view(model: Model) -> Element(Msg) {
  let timeline = tl.view(from: model.selected)
  html.div([], [header_view(), timeline_view(timeline, model)])
}

fn header_view() -> Element(Msg) {
  html.header([], [
    html.h1([], [html.text("Time Zone Fren")]),
    html.button([event.on_click(GoToNow)], [html.text("Now")]),
  ])
}

fn timeline_view(timeline: Timeline, model: Model) -> Element(Msg) {
  html.div([attribute.class("timeline-scroll")], [
    html.div(
      [attribute.class("timeline")],
      list.flatten([
        [
          html.div([attribute.class("header-spacer")], []),
          hour_scale_view(timeline),
        ],
        list.flatten(list.index_map(model.locations, fn(location, index) {
          let row_index = index + 2
          [
            location_label_view(location, model.selected, row_index),
            location_strip_row(location, timeline, model.selected, row_index),
          ]
        })),
        [
          html.div(
            [
              attribute.class("cursors-overlay"),
              attribute.style(
                "grid-row",
                "2 / span " <> int.to_string(list.length(model.locations)),
              ),
            ],
            [
              selected_cursor_view(timeline, model.selected),
              now_marker_view(timeline, model.now),
            ],
          ),
        ],
      ]),
    ),
  ])
}

fn hour_scale_view(timeline: Timeline) -> Element(Msg) {
  html.div(
    [attribute.class("hour-scale"), event.on("click", select_at_decoder())],
    list.map(hour_tick_positions(timeline), fn(tick) {
      let #(position, label) = tick
      html.span(
        [
          attribute.class("hour-tick"),
          attribute.style("left", pixels(position)),
        ],
        [html.text(label)],
      )
    }),
  )
}

const hours_per_day: Int = 24

fn hour_tick_positions(timeline: Timeline) -> List(#(Float, String)) {
  hour_offsets()
  |> list.map(fn(hour_offset) {
    let instant = hour_offset_to_instant(timeline, hour_offset)
    let position = timeline |> tl.position_of(instant)
    #(position, format_hour_label(hour_offset))
  })
}

fn hour_offset_to_instant(timeline: Timeline, hour_offset: Int) -> Timestamp {
  let position_at_hour =
    int.to_float(hour_offset)
    *. int.to_float(tl.timeline_width_px)
    /. int.to_float(hours_per_day)
  timeline |> tl.instant_at(position_at_hour)
}

fn format_hour_label(hour_offset: Int) -> String {
  case hour_offset % hours_per_day {
    hour if hour < 10 -> "0" <> int.to_string(hour)
    hour -> int.to_string(hour)
  }
}

fn location_label_view(
  location: Location,
  selected: Timestamp,
  row_index: Int,
) -> Element(Msg) {
  let local = local_view.new(selected, location.zone)
  html.div(
    [
      attribute.class("location-label"),
      attribute.style("grid-row", int.to_string(row_index)),
    ],
    [
      html.div([attribute.class("city")], [html.text(location.city)]),
      html.div([attribute.class("region")], [
        html.text(location_region_line(location)),
      ]),
      html.div([attribute.class("time")], [
        html.text(format.time_of_day(local.time)),
      ]),
      html.div([attribute.class("date")], [
        html.text(format.short_date(local.date, local.weekday)),
      ]),
      html.div([attribute.class("offset")], [
        html.text(format.offset(local.offset_minutes)),
      ]),
    ],
  )
}

fn location_region_line(location: Location) -> String {
  case location.region {
    "" -> location.country
    region -> region <> ", " <> location.country
  }
}

fn location_strip_row(
  location: Location,
  timeline: Timeline,
  selected: Timestamp,
  row_index: Int,
) -> Element(Msg) {
  let selected_local = local_view.new(selected, location.zone)
  html.div(
    [
      attribute.class(strip_classes(selected_local)),
      attribute.style("grid-row", int.to_string(row_index)),
      event.on("click", select_at_decoder()),
    ],
    working_hours_bands(location, timeline),
  )
}

fn select_at_decoder() -> decode.Decoder(Msg) {
  decode.at(["offsetX"], decode.float) |> decode.map(SelectAt)
}

fn strip_classes(selected_local: LocalView) -> String {
  case weekday.is_weekend(selected_local.weekday) {
    True -> "location-strip weekend"
    False -> "location-strip"
  }
}

fn working_hours_bands(
  location: Location,
  timeline: Timeline,
) -> List(Element(Msg)) {
  hour_boundary_instants(timeline)
  |> list.window_by_2()
  |> list.filter_map(fn(pair) {
    let #(from, to) = pair
    let start_lv = local_view.new(from, location.zone)
    case is_working_hour(start_lv) {
      True -> {
        let left = timeline |> tl.position_of(from)
        let right = timeline |> tl.position_of(to)
        Ok(
          html.div(
            [
              attribute.class("working-hours"),
              attribute.style("left", pixels(left)),
              attribute.style("width", pixels(right -. left)),
            ],
            [],
          ),
        )
      }
      False -> Error(Nil)
    }
  })
}

const work_day_start_hour: Int = 9

const work_day_end_hour: Int = 17

fn is_working_hour(lv: LocalView) -> Bool {
  case weekday.is_weekend(lv.weekday) {
    True -> False
    False ->
      lv.time.hours >= work_day_start_hour && lv.time.hours < work_day_end_hour
  }
}

fn hour_boundary_instants(timeline: Timeline) -> List(Timestamp) {
  hour_offsets()
  |> list.map(fn(hour_offset) { hour_offset_to_instant(timeline, hour_offset) })
}

fn hour_offsets() -> List(Int) {
  list.repeat(0, hours_per_day + 1)
  |> list.index_map(fn(_, index) { index })
}

fn selected_cursor_view(
  timeline: Timeline,
  selected: Timestamp,
) -> Element(Msg) {
  html.div(
    [
      attribute.class("selected-cursor"),
      attribute.style("left", pixels(timeline |> tl.position_of(selected))),
    ],
    [],
  )
}

fn now_marker_view(timeline: Timeline, now: Timestamp) -> Element(Msg) {
  html.div(
    [
      attribute.class("now-marker"),
      attribute.style("left", pixels(timeline |> tl.position_of(now))),
    ],
    [],
  )
}

fn pixels(value: Float) -> String {
  float.to_string(value) <> "px"
}
