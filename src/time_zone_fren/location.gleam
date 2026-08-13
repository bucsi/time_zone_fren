import gleam/list
import gtz.{type TimeZone}

pub type Location {
  Location(
    id: String,
    city: String,
    region: String,
    country: String,
    timezone_name: String,
    zone: TimeZone,
  )
}

type LocationSpec {
  LocationSpec(
    id: String,
    city: String,
    region: String,
    country: String,
    timezone_name: String,
  )
}

pub fn defaults() -> List(Location) {
  list.map(default_specs(), unsafe_from_spec)
}

fn default_specs() -> List(LocationSpec) {
  [
    LocationSpec(
      id: "budapest",
      city: "Budapest",
      region: "",
      country: "Hungary",
      timezone_name: "Europe/Budapest",
    ),
    LocationSpec(
      id: "boise",
      city: "Boise",
      region: "Idaho",
      country: "USA",
      timezone_name: "America/Boise",
    ),
    LocationSpec(
      id: "indianapolis",
      city: "Indianapolis",
      region: "Indiana",
      country: "USA",
      timezone_name: "America/Indiana/Indianapolis",
    ),
    LocationSpec(
      id: "montreal",
      city: "Montreal",
      region: "Quebec",
      country: "Canada",
      timezone_name: "America/Toronto",
    ),
    LocationSpec(
      id: "london",
      city: "London",
      region: "",
      country: "United Kingdom",
      timezone_name: "Europe/London",
    ),
  ]
}

fn unsafe_from_spec(spec: LocationSpec) -> Location {
  let assert Ok(zone) = gtz.build(spec.timezone_name)
    as { "unknown IANA timezone: " <> spec.timezone_name }
  Location(
    id: spec.id,
    city: spec.city,
    region: spec.region,
    country: spec.country,
    timezone_name: spec.timezone_name,
    zone:,
  )
}
