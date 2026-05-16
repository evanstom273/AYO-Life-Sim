## Summary
- Pivot the Calendar/Energy system from “actions consume energy” to **real-time energy drain** driven by a `Timer`.
- Add a clean **pause/resume API** (`set_energy_paused(is_paused: bool)`) and automatically pause drain when not on **Overview**.
- Replace the old modal “Out of Energy” dialog with a **juicy, non-blocking zero-energy state**: screen shake + temporary “OUT OF ENERGY!” label animation.

## Current State Analysis (Grounded)
- The implementation lives in [WeeklyCalendarCard.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/WeeklyCalendarCard.gd).
- Current behavior:
  - `consume_energy(amount)` reduces energy and updates UI; previously evolved into a modal popup and extra effects.
  - Energy UI is updated via `_energy_label` + `_energy_bar` (absolute paths into the RightBar in [MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn#L3779-L3808)).
- Tab navigation is controlled by [MainUI.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/MainUI.gd); it hides the Overview content when switching to other tabs.

## Decisions Locked (From You)
- Shake target node: **`/root/Control/ColorRect`** (reset to `Vector2.ZERO`).
- Auto-pause rule: **pause energy drain when off-Overview**.
- Tick-rate updates: changing `energy_tick_rate` should update the timer **immediately**.

## Proposed Changes

### 1) WeeklyCalendarCard: replace action-cost energy with real-time drain
File: [WeeklyCalendarCard.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/WeeklyCalendarCard.gd)

#### 1.1 Add exported tick rate + Timer
- Add:
  - `@export_range(2.0, 10.0, 0.5) var energy_tick_rate: float = 3.0` (implemented with a setter so changes propagate live)
  - `var _energy_timer: Timer`
- In `_ready()`:
  - Create timer dynamically: `_energy_timer = Timer.new()`
  - Configure:
    - `_energy_timer.wait_time = energy_tick_rate`
    - `_energy_timer.one_shot = false`
    - `_energy_timer.autostart = true`
  - `add_child(_energy_timer)`
  - Connect: `_energy_timer.timeout.connect(_on_energy_tick)`

#### 1.2 Implement drain tick
- Add `_on_energy_tick()`:
  - `current_energy = maxi(0, current_energy - 1)`
  - `_update_energy_ui()`
  - If `current_energy == 0`:
    - `_energy_timer.stop()`
    - `_on_energy_depleted()`

#### 1.3 Implement pausing API (for other scripts)
- Add `func set_energy_paused(is_paused: bool) -> void`:
  - If `_energy_timer == null`, return.
  - Use `_energy_timer.paused = is_paused` (and if resuming while stopped + energy > 0, call `_energy_timer.start()`).

### 2) Juicy zero-energy state (no modals)
File: [WeeklyCalendarCard.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/WeeklyCalendarCard.gd)

#### 2.1 Remove modal logic completely
- Delete:
  - `out_of_energy_popup: AcceptDialog`
  - Any `_show_out_of_energy_popup`, dialog creation, dialog tweens, and dialog signal handlers.

#### 2.2 Screen shake (0.2s) on ColorRect, then reset to Vector2.ZERO
- Implement `_on_energy_depleted()`:
  - Get main wrapper: `var wrapper := get_node_or_null("/root/Control/ColorRect") as Control`
  - Use `create_tween()` to rapidly tween wrapper `position.x` left/right over ~0.2s, then return wrapper `position = Vector2.ZERO`.
  - Keep this non-blocking (no popup).

#### 2.3 Spawn temporary warning label with pop + fade out
- In `_on_energy_depleted()`:
  - Create a `Label` dynamically, add it under the same wrapper (`ColorRect`) so it overlays everything.
  - Configure:
    - `text = "OUT OF ENERGY!"`
    - red font color
    - large font size (e.g. 28–36)
    - centered placement
  - Animate with a tween over 1.5s:
    - pop up (scale up and/or move up)
    - fade out (`modulate.a -> 0`)
  - After tween, `queue_free()` the label.

### 3) Refactor actions API: consume_energy → attempt_action
File: [WeeklyCalendarCard.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/WeeklyCalendarCard.gd)
- Replace `consume_energy(amount: int)` with:
  - `func attempt_action() -> bool`
  - Returns `true` if `current_energy > 0`
  - If `false`, do a tiny micro-shake (very small, short tween) and return `false`
- Update `_input`:
  - Enter key should call `attempt_action()` (no args).

### 4) Resetting: restart timer each week
File: [WeeklyCalendarCard.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/WeeklyCalendarCard.gd)
- Update `reset_energy()`:
  - Set `current_energy = max_energy`
  - `_update_energy_ui()`
  - Ensure timer is running again for the new week:
    - `_energy_timer.paused = false`
    - `_energy_timer.start()`

### 5) Auto pause when off-Overview
File: [MainUI.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/MainUI.gd)
- Add an `@onready` reference to the calendar node (the `CalendarCard` with WeeklyCalendarCard script).
- In `_set_section(section)`:
  - After computing `is_overview`, call:
    - `calendar_card.call("set_energy_paused", not is_overview)` (guarded with `has_method`/`get_node_or_null`).

## Assumptions & Constraints
- Timer-driven drain is per-second-ish (per tick) and independent of player actions.
- When energy is 0:
  - Timer stays stopped until time advances to next week (reset_energy).
  - attempt_action() returns false; it does not block the UI with modals.
- No new assets; use existing theme/font and simple tween effects.

## Verification Steps
- In Overview tab:
  - Confirm energy drains by 1 every `energy_tick_rate` seconds.
  - Confirm energy bar value updates and color shifts toward red as it decreases.
- When energy reaches 0:
  - Confirm timer stops.
  - Confirm screen shake + “OUT OF ENERGY!” label plays and fades out.
  - Confirm UI remains usable (non-blocking), but `attempt_action()` returns false and does micro-shake.
- Switch to any non-Overview tab:
  - Confirm drain pauses (energy stays constant).
  - Switch back to Overview:
    - Confirm drain resumes.
