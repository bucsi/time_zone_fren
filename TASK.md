# World Time Buddy–style Timezone Timeline

## 1. Goal

Build a small, client-side **World Time Buddy–style timezone timeline** in **Gleam + Lustre**.

The application answers:

> “What time is it in these locations at the same moment?”

The MVP is intentionally limited to a fixed set of five cities and a timeline for comparing their local times.

The application should be:

* client-side
* timezone/DST-aware
* simple
* keyboard and pointer usable
* visually focused on the timeline rather than configuration

---

# 2. MVP locations

The MVP has exactly these five locations, in this order:

| City         | Region         | IANA timezone                  |
| ------------ | -------------- | ------------------------------ |
| Budapest     | Hungary        | `Europe/Budapest`              |
| Boise        | Idaho, USA     | `America/Boise`                |
| Indianapolis | Indiana, USA   | `America/Indiana/Indianapolis` |
| Montreal     | Quebec, Canada | `America/Toronto`              |
| London       | United Kingdom | `Europe/London`                |

These should be represented as application data rather than duplicated throughout the UI implementation.

For example, conceptually:

```gleam
type Location {
  Location(
    id: String,
    city: String,
    region: String,
    country: String,
    timezone: String,
  )
}
```

The exact type/module names are implementation details.

---

# 3. Technology

Use:

* **Gleam**
* **Lustre**
* JavaScript target
* `gleam_time`
* Plinth or another appropriate browser API binding where browser APIs are needed

For timezone functionality, investigate the current Gleam ecosystem and choose an appropriate implementation.

Potential candidates include:

* `gtempo`
* `gtz`
* Birl
* browser timezone APIs through Plinth
* other suitable Gleam packages

**Do not assume that `gtempo` + `gtz` are required.**

The implementation should select whatever combination provides reliable:

* absolute timestamps/instants
* IANA timezone conversion
* DST handling
* local date/time extraction
* UTC offset information

Timezone functionality should be isolated behind a small application-level abstraction so that the rest of the code does not depend directly on whichever library is chosen.

---

# 4. Core time model

The central architectural rule is:

> **The selected time is always represented as an absolute instant.**

Do not represent the selected time as:

```text
14:30 Europe/Budapest
```

Instead represent it as an unambiguous instant, conceptually:

```text
2026-08-13T12:30:00Z
```

Every location derives its local date/time from that instant.

Conceptually:

```text
                 selected instant
                       │
          ┌────────────┼────────────┐
          ▼            ▼            ▼
      Budapest       Boise       London
          │            │            │
          ▼            ▼            ▼
      local time    local time    local time
```

This is essential for correct DST and date-boundary handling.

---

# 5. Application state

The application model should contain the minimum state required to render the timeline.

Conceptually:

```gleam
type Model {
  Model(
    locations: List(Location),
    selected: Timestamp,
    now: Timestamp,
  )
}
```

The exact timestamp type depends on the chosen time implementation.

Do not store derived values such as:

* local time for each city
* UTC offset for each city
* formatted time strings
* cursor pixel position

These should be calculated from the model when required.

---

# 6. Timezone abstraction

Create a small module responsible for converting an absolute instant into local timezone information.

Conceptually, the rest of the application should be able to request:

```text
local date
local time
UTC offset
weekday
```

for:

```text
instant + IANA timezone
```

For example:

```text
local_time(
  selected_instant,
  "America/Boise",
)
```

The implementation can use whichever Gleam/browser timezone facilities prove most appropriate.

The application must not implement IANA timezone or DST rules itself.

---

# 7. Timeline

The main UI is a horizontal timeline shared by all locations.

The MVP should display approximately **24 hours** around the selected instant.

Conceptually:

```text
        08    10    12    14    16    18    20
         │     │     │     │     │     │     │
         ├─────┼─────┼─────┼─────┼─────┼─────┤
Budapest │           │ 14:00     │           │
Boise    │           │ 06:00     │           │
Indiana  │           │ 08:00     │           │
Montreal │           │ 08:00     │           │
London   │           │ 13:00     │           │
```

The exact visual appearance is implementation-dependent.

The important requirement is:

> All location rows represent the same absolute timeline.

Do not implement each city as an independent timeline.

---

# 8. Timeline coordinate system

Represent the timeline as an absolute time interval:

```text
start_instant
end_instant
```

The UI converts between:

```text
instant ↔ horizontal position
```

The selected instant determines the position of the main cursor.

The implementation should use a sufficiently fine-grained unit internally, such as minutes.

For MVP:

* clicking should select a sensible time, preferably snapped to 15-minute increments;
* left/right keyboard movement should move by 15 minutes;
* Shift + left/right should move by one hour.

---

# 9. Location rows

Each location gets one horizontal row.

Each row should show:

* city
* region/country
* local time
* local date when useful
* UTC offset

Example:

```text
Budapest
Hungary
14:30
Thu 13 Aug
UTC+2
```

The exact layout is up to the implementation.

The UTC offset must be derived from the selected instant.

For example, the application must not permanently associate:

```text
London → UTC+0
```

because the offset changes with DST.

---

# 10. Selected-time cursor

Render a prominent vertical cursor through the entire timeline.

Conceptually:

```text
                    │
                    │ selected
                    ▼
────────────────────┼────────────────────
                    │
Budapest            │ 14:00
                    │
────────────────────┼────────────────────
Boise               │ 06:00
                    │
────────────────────┼────────────────────
Indianapolis        │ 08:00
                    │
────────────────────┼────────────────────
Montreal             │ 08:00
                    │
────────────────────┼────────────────────
London               │ 13:00
                    │
```

The cursor position must always be derived from `selected`.

Do not store its pixel position as application state.

---

# 11. Selecting a time

The user must be able to change the selected instant by interacting with the timeline.

### Mouse/pointer

Clicking on the timeline selects the corresponding time.

Dragging the selected cursor moves it continuously.

Use pointer events where practical so that mouse and touch interaction can share the same implementation.

### Keyboard

The timeline/cursor should be keyboard accessible.

Suggested controls:

```text
←       -15 minutes
→       +15 minutes

Shift+← -1 hour
Shift+→ +1 hour
```

The keyboard implementation should manipulate the absolute selected instant rather than a visual coordinate.

---

# 12. Current time

The application should track the current instant and display a separate “now” marker.

Conceptually:

```text
              now
               │
               │
───────────────┼────────────────────────
                       │
                       │ selected
                       │
```

The current time should update periodically while the page is open.

Minute-level updates are sufficient.

Provide a visible **Now** control that sets:

```text
selected = current time
```

If the selected instant and current instant coincide, the two indicators can be visually combined.

---

# 13. Date handling

The application must correctly display different local dates.

For example, one location may show:

```text
Thu 13 Aug
23:30
```

while another shows:

```text
Fri 14 Aug
00:30
```

The date shown for each row must be calculated in that location's timezone.

The timeline must also handle crossing midnight while remaining a single absolute timeline.

---

# 14. DST handling

Correct DST behavior is a core MVP requirement.

The application must not use manually configured offsets.

Test at least:

* Europe/Budapest
* Europe/London
* America/Boise
* America/Indiana/Indianapolis
* America/Toronto

around their DST transitions.

Do not assume that all locations transition on the same date.

The architecture should always calculate:

```text
absolute instant
+
IANA timezone
=
local date/time + current UTC offset
```

---

# 15. Working-hours visualization

For the MVP, all locations use the same conceptual working schedule:

```text
Monday–Friday
09:00–17:00
```

This is **local time for each location**.

There is no per-location working-hours configuration.

Render the working-hours period as a subtle visual background/region on each location row.

For example:

```text
Budapest
        ┌──────────────────────────┐
        │      working hours       │
────────┴──────────────────────────┴────────
```

The working-hours region must be calculated from the location's local date/time, including DST.

The application should also visually distinguish weekends.

---

# 16. UI structure

A reasonable initial Lustre component structure is:

```text
App
├── Header
│   ├── title
│   ├── Now button
│   └── date/navigation controls
│
└── Timeline
    ├── TimelineHeader
    ├── SelectedCursor
    └── LocationRow × 5
```

Suggested source modules:

```text
src/
├── main.gleam
├── model.gleam
├── update.gleam
├── view.gleam
├── location.gleam
├── locations.gleam
├── timezone.gleam
└── timeline.gleam
```

This is only a suggested organization. Do not create modules purely to match this list if the implementation remains simpler without them.

---

# 17. Lustre state/update model

Use the normal Lustre Model–View–Update architecture.

Messages should cover the actual interactions, conceptually:

```gleam
type Msg {
  Tick
  GoToNow
  SetSelectedInstant(Timestamp)
  MoveSelection(Minutes)
  PointerDown(...)
  PointerMove(...)
  PointerUp
}
```

Keep state transitions centralized in `update`.

The view should derive displayed local times and timeline positions from the model rather than mutating DOM state independently.

---

# 18. Visual design

The application should be a compact utility rather than a SaaS-style dashboard.

Priorities:

1. timeline readability
2. city identification
3. selected-time visibility
4. working-hours visibility
5. clear local times
6. minimal visual clutter

Use plain CSS initially.

Support both light and dark presentation, but do not spend significant implementation effort on elaborate theming.

---

# 19. Responsive behavior

Desktop is the primary target.

The timeline should remain usable on narrow screens by allowing horizontal scrolling rather than attempting to compress the entire 24-hour timeline into the viewport.

Location rows must remain horizontally aligned with the common timeline.

---

# 20. Tests

Timezone correctness should be tested independently from the UI.

Test at least:

### Basic conversion

* Budapest → London
* Budapest → Boise
* Budapest → Indianapolis
* Budapest → Montreal
* Budapest → London

### DST

Test instants around DST transitions for all five timezones.

### Midnight/date boundaries

Test cases where one location is on the previous/next local date.

### Current offset

Verify that the displayed UTC offset is derived from the selected instant rather than being hard-coded.

### Timeline conversion

Test:

```text
instant → x coordinate
x coordinate → instant
```

including the beginning/end of the visible timeline.

### Selection increments

Verify:

```text
left/right = 15 minutes
Shift+left/right = 1 hour
```

---

# 21. MVP acceptance criteria

The MVP is complete when:

* [ ] It is implemented in Gleam + Lustre.
* [ ] It runs entirely client-side.
* [ ] The five required cities are displayed in the specified order.
* [ ] Each city uses an IANA timezone.
* [ ] The selected time is an absolute instant.
* [ ] All cities display the same instant in their local timezone.
* [ ] DST is handled correctly.
* [ ] Local dates are displayed correctly.
* [ ] A roughly 24-hour horizontal timeline is visible.
* [ ] The user can click the timeline to select a time.
* [ ] The user can drag the selected-time cursor.
* [ ] Keyboard controls can move the selected time.
* [ ] A “Now” action returns to the current time.
* [ ] A current-time marker is displayed.
* [ ] Monday–Friday 09:00–17:00 local working hours are visually indicated.
* [ ] Weekends are distinguishable.
* [ ] The timeline remains usable on narrow screens.
* [ ] Core timezone and timeline behavior has automated tests.

---

# 22. Post-MVP: Dynamic cities

After the MVP is stable, replace the fixed five-city list with a city catalogue.

The catalogue should contain, at minimum:

```text
city name
region/state where useful
country
IANA timezone
```

Add a city search UI.

The user should be able to:

* search for a city
* add it to the timeline
* remove a city
* reorder cities

The existing timeline implementation should not need fundamental changes.

---

# 23. Post-MVP: Persistence

Persist the user's selected locations locally in browser storage.

Store timezone identifiers rather than calculated times.

For example:

```json
{
  "locations": [
    "Europe/Budapest",
    "America/Boise",
    "America/Indiana/Indianapolis",
    "America/Toronto",
    "Europe/London"
  ]
}
```

On startup:

1. load the saved locations;
2. validate them;
3. use them if valid;
4. otherwise use the default city list.

---

# 24. Post-MVP: URL handling

Add shareable URL state.

The URL should be able to represent:

* selected locations
* selected instant

For example, conceptually:

```text
/?locations=Europe/Budapest,America/Boise,America/Toronto
&at=2026-08-13T12:30:00Z
```

The exact encoding is an implementation decision.

URL state should take precedence over locally persisted locations when a shared URL is opened.

A URL containing a selected instant should restore that exact instant rather than replacing it with the current time.

Malformed or unknown URL values should be ignored safely.

Updating the selected time should not create a browser history entry for every cursor movement; use URL replacement rather than navigation.

Provide a way to copy/share the current URL.

---

# 25. Later visual refinement

After dynamic cities, persistence, and URL handling are complete, consider replacing the fixed working-hours visualization with broader local-time categories.

Potential categories:

```text
Early morning
Morning
Working hours
Afternoon
Evening
Night
```

These would be based purely on **local time of day**, rather than configurable working schedules.

This is a visual refinement, not part of the MVP.

---

# 26. Implementation sequence

A coding agent should implement the project in this order:

## Phase 1 — Bootstrap

1. Create the Gleam JavaScript project.
2. Add Lustre.
3. Add `gleam_time`.
4. Add Plinth or the required browser API bindings.
5. Investigate the available timezone implementations.
6. Choose the timezone implementation.
7. Create the timezone abstraction.
8. Verify basic browser execution.

## Phase 2 — Domain

9. Define `Location`.
10. Define the five MVP locations.
11. Define the application model.
12. Implement absolute-instant → local-time conversion.
13. Implement UTC offset calculation.
14. Implement local weekday/date calculation.
15. Write timezone tests.
16. Write DST tests.
17. Write date-boundary tests.

## Phase 3 — Timeline

18. Implement the 24-hour timeline interval.
19. Implement instant → horizontal position.
20. Implement horizontal position → instant.
21. Render the timeline header.
22. Render the five location rows.
23. Render local time/date/offset.
24. Render the selected-time cursor.
25. Render local 09:00–17:00 working-hour regions.
26. Render weekend distinction.

## Phase 4 — Interaction

27. Implement click-to-select.
28. Implement cursor dragging.
29. Implement keyboard movement.
30. Implement current-time tracking.
31. Implement the Now action.
32. Add date navigation if needed for moving outside the initial visible range.

## Phase 5 — UI refinement

33. Align all rows and timeline elements.
34. Add responsive horizontal scrolling.
35. Add basic light/dark styling.
36. Add keyboard focus/accessibility.
37. Test the UI manually across the five locations.
38. Test DST and midnight transitions manually.

## Phase 6 — MVP verification

39. Run all automated tests.
40. Verify all five cities and their IANA zones.
41. Verify click/drag/keyboard selection.
42. Verify current-time behavior.
43. Verify working-hours visualization.
44. Verify date boundaries.
45. Verify narrow-screen behavior.
46. Verify every MVP acceptance criterion.

Only after these steps are complete should dynamic city selection, persistence, and URL handling be introduced.

