## Summary
- Restructure the Overview UI so **Energy** is displayed under the **Calendar** (center area) instead of the right Stats panel.
- Remove the manual time-skip buttons under the Calendar and convert “Next Week” into a hidden-by-default **NextWeekButton** that appears only when energy hits 0.
- Add a root-level **Pause overlay** (ESC toggles) that pauses the real-time drain and blocks input until Resume.
- Wire WeeklyCalendarCard to show/hide the Energy bar vs NextWeekButton based on depleted/reset states, and hook Resume + ESC to the existing pause API.

## Current State Analysis (Grounded)
- Main scene root is [MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn) with root node `Control` and a background `ColorRect` child.
- Calendar UI is `CalendarCard` under:
  - `ColorRect/.../CenterVBox/HBoxContainer/CalendarCard` ([MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn#L2813-L3150))
  - It currently contains `NextWeekBtn`, `SkipMonthBtn`, `SkipYearBtn`, `AdvanceTimeBtn`.
- Energy UI currently lives in the right Stats card as `EnergyRow` containing `Icon`, `Label`, `Bar` (ProgressBar), and `Value` ([MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn#L3783-L3821)).
- Energy drain + pause API already exists in [WeeklyCalendarCard.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/WeeklyCalendarCard.gd), and MainUI currently auto-pauses energy off-Overview via `set_energy_paused(not is_overview)` ([MainUI.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/MainUI.gd)).

## Decisions Locked (From You)
- NextWeekButton behavior: **Advance time** (week/month/year updates) when clicked.
- Energy move: move the **entire EnergyRow** (icon/label/bar/value) under the Calendar (not just the bar).
- Pause overlay should **block input** to the UI underneath.

## Proposed Changes

### Part 1 — UI Restructuring (MainUI.tscn)
File: [MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn)

#### 1) Move EnergyRow under CalendarCard
- Remove `EnergyRow` from:
  - `RightBar/.../StatsCard/.../Rows/EnergyRow`
- Re-parent `EnergyRow` (unchanged children `Icon`, `Label`, `Bar`, `Value`) into the Calendar card hierarchy so it sits directly under the calendar content.
  - Target placement: inside `CalendarCard/MarginContainer/VBoxContainer`, immediately after the `Helper` label and before the action-buttons VBox.
- Adjust layout props to fit the Calendar card:
  - Ensure the ProgressBar keeps `theme_override_styles/background` and `fill` (currently SubResources) so the look matches.

#### 2) Delete manual time-skip buttons
- Delete nodes under CalendarCard:
  - `SkipMonthBtn`
  - `SkipYearBtn`
  - `AdvanceTimeBtn`
  - Also remove their container `HBoxContainer2` if it becomes empty.

#### 3) Rename + hide Next Week button
- Rename node `NextWeekBtn` → `NextWeekButton`.
- Set `visible = false` on `NextWeekButton` in the scene.
- Keep it in the same location under CalendarCard (it will be shown when energy hits 0).

#### 4) Add Pause overlay at root level
- Add a new sibling node under the root `Control` (same level as the background `ColorRect`), named `PauseOverlay`:
  - Type: `ColorRect`
  - Full-screen anchors preset; `color = Color(0,0,0,0.5)`; `visible = false`
  - `mouse_filter = STOP` to block clicks to underlying UI.
- Children:
  - `CenterContainer`
    - `VBoxContainer` (centered)
      - `Label` text: `PAUSED`
      - `Button` name: `ResumeButton`, text: `Resume`

### Part 2 — Pause Logic (WeeklyCalendarCard.gd)
File: [WeeklyCalendarCard.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/WeeklyCalendarCard.gd)

#### 1) Wire PauseOverlay + ResumeButton references
- Add `@onready` references:
  - `_pause_overlay: Control = get_node("/root/Control/PauseOverlay")`
  - `_resume_button: Button = get_node("/root/Control/PauseOverlay/CenterContainer/VBoxContainer/ResumeButton")`
- In `_ready()`, connect `_resume_button.pressed` to a function that:
  - `set_energy_paused(false)`
  - `_pause_overlay.visible = false`

#### 2) Add ESC pause toggle
- Add `_input(event: InputEvent) -> void` (or extend the existing one if present) to detect:
  - `event.is_action_pressed("ui_cancel")`
- On press, toggle pause state:
  - `var new_paused := not _energy_timer.paused`
  - `set_energy_paused(new_paused)`
  - `_pause_overlay.visible = new_paused`
- Keep existing input behavior intact (e.g., Space/Enter bindings if still desired).

### Part 3 — Zero State / Next Week Swap (WeeklyCalendarCard.gd)
File: [WeeklyCalendarCard.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/WeeklyCalendarCard.gd)

#### 1) Update node references for relocated EnergyRow and renamed NextWeekButton
- Replace the old absolute RightBar energy-node paths with **local** paths inside CalendarCard:
  - `_energy_bar` should point to the moved `EnergyRow/Bar`
  - `_energy_label` should point to the moved `EnergyRow/Value` (since that moves too)
- Update `_next_week_btn` to reference `NextWeekButton`.
- Remove now-deleted button references (`_skip_month_btn`, `_skip_year_btn`, `_advance_time_btn`) and their signal hookups.

#### 2) Depleted state UI swap
- In `_on_energy_depleted()`:
  - Hide the Energy **ProgressBar** only: `_energy_bar.visible = false`
  - Show `NextWeekButton`: `_next_week_btn.visible = true`

#### 3) Next week start behavior
- Connect `NextWeekButton.pressed` to advance time one week (per your decision):
  - `advance_time(1)` (this updates week/month/year and calls `reset_energy()` via `_process_single_week`)
- Ensure the “swap back” happens on reset:
  - Hide `NextWeekButton`
  - Show Energy ProgressBar again
  - Ensure timer is running for the new week (reset already starts it; keep/start it explicitly if needed)

## Assumptions & Constraints
- Pause overlay is only intended for the MainUI scene (root path `/root/Control/...` is stable in this project).
- Auto-pause off-Overview (MainUI.gd) remains active; ESC pause is an additional manual pause.
- No new assets are introduced; overlay uses existing UI theme defaults.

## Verification Steps
- UI layout:
  - EnergyRow appears directly under the Calendar card; it no longer appears in the right Stats panel.
  - Skip buttons are removed; only NextWeekButton exists (hidden by default).
  - PauseOverlay exists at root, hidden by default.
- Pause:
  - Press ESC on Overview: timer pauses, overlay shows, drain stops.
  - Click Resume: overlay hides and drain resumes.
  - Overlay blocks interaction with underlying UI while visible.
- Depleted:
  - When energy hits 0: Energy bar hides, NextWeekButton shows.
  - Clicking NextWeekButton advances the week labels and restores energy + bar, hides NextWeekButton, and restarts drain.
