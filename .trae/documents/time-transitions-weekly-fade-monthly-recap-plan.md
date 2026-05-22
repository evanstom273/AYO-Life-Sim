# Plan: Weekly Fade + Monthly Recap Transitions

## Summary

Add two time-system transition effects:

1. **Weekly Transition (subtle):** a quick full-screen fade-out/fade-in (~0.3–0.5s total) when the week advances via the “Next Week” flow. The calendar/header week label updates while the screen is dark.
2. **Monthly Transition (recap overlay):** when a week advance rolls the month forward, show a modal recap overlay (dark, clean, consistent with Pause/Depleted overlays). It pauses energy drain while visible, supports dismissal via **Continue** and **ESC**, and does not conflict with PAUSED or OUT OF ENERGY overlays.

## Current State Analysis (Grounded)

### Time advancement

- Week advancement is driven by `WeeklyCalendarCard.gd`:
  - “Next Week” button → `_on_next_week_button_pressed()` → `advance_time(1)` ([WeeklyCalendarCard.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/WeeklyCalendarCard.gd#L149-L151))
  - `advance_time()` loops and calls `_process_single_week()` which increments week/month/year ([WeeklyCalendarCard.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/WeeklyCalendarCard.gd#L360-L379))
  - `_update_labels()` updates the calendar labels + the top Meta header label.

### Existing overlays to avoid conflicting with

- `PauseOverlay` (ColorRect dim) is a top-level node in `MainUI.tscn` with `color = Color(0,0,0,0.5)` ([MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn#L4140-L4175))
- `DepletedOverlay` is also top-level, with a centered card styled by `ExtResource("21_card_dark")` ([MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn#L4176-L4251))
- Pause/depleted behavior is implemented in `WeeklyCalendarCard.gd` and already toggles `set_energy_paused(...)`.

### “Events This Month” data

- There is no runtime event log system today; “Life Log” entries are static placeholders in `MainUI.tscn`.
- Decision: monthly recap shows an **empty state** (“No major events this month.”) for now.

## Assumptions & Decisions

- Weekly fade applies to **full screen** (top-level overlay), but is layered so it does not break PAUSED / OUT OF ENERGY overlays.
- Monthly recap is shown when a week advance causes `week_index` rollover (week 4 → week 1) and increments `month_index`.
- Monthly recap is dismissed by **Continue** button or **ESC** (ESC closes recap instead of toggling pause while recap is visible).
- Monthly finances use the same “Monthly Income/Expenses” assumptions currently shown in the UI:
  - Income = `player_data.current_job.salary` (or 0)
  - Expenses = 0 (until an expenses system exists)
  - End-of-month bank = `player_data.bank_balance`
- Stat changes are computed by snapshotting the player’s stats at the start of the month and diffing at month-end:
  - If no stats changed, show an empty state (“No stat changes this month.”).

## Proposed Changes

### 1) Add a weekly fade overlay (scene)

**File:** `scenes/main/MainUI.tscn`

Add a new top-level node:

- `WeekTransitionOverlay` (ColorRect)
  - Fullscreen anchors
  - `visible = false`
  - `mouse_filter = MOUSE_FILTER_IGNORE` (so it doesn’t block input for long)
  - `color = Color(0, 0, 0, 1)` and start with `modulate.a = 0.0` (fade via modulate alpha)

Placement:
- Insert alongside the existing top-level overlays so z-order is controlled. Recommended order:
  - Base UI (`ColorRect` etc.)
  - `WeekTransitionOverlay` (used for quick fades)
  - `PauseOverlay`
  - `DepletedOverlay`
  - `MonthlyRecapOverlay` (new, see next section)

### 2) Add a monthly recap overlay (scene)

**File:** `scenes/main/MainUI.tscn`

Add a new top-level overlay modeled after `DepletedOverlay` styling:

- `MonthlyRecapOverlay` (ColorRect)
  - Fullscreen anchors
  - `visible = false`
  - `mouse_filter = MOUSE_FILTER_STOP`
  - `color = Color(0, 0, 0, 0.5)` (match pause dim)
- `CenterContainer` → `PanelContainer`
  - `theme_override_styles/panel = ExtResource("21_card_dark")` (same as depleted modal)
- Inside panel:
  - `HeadingLabel` (e.g., “May 2025”)
  - `EventsSection`:
    - `EventsTitle` label
    - `EventsEmptyLabel` label (default visible): “No major events this month.”
    - `EventsList` VBoxContainer (hidden until real events exist)
  - `FinancesSection`:
    - labels for Income, Expenses, End Balance (values populated in script)
  - `StatsSection`:
    - `StatsEmptyLabel` label (default visible): “No stat changes this month.”
    - `StatsList` VBoxContainer (populated with “+X Happiness”, etc.)
  - `ContinueButton` styled using the existing “action button” styleboxes:
    - `StyleBoxFlat_action_btn_normal/hover/pressed/disabled` and focus style `StyleBoxFlat_ncioe` (copy the pattern used by `DepletedOverlay/NextWeekButton`).

### 3) Weekly fade logic + month-change detection (script)

**File:** `scripts/WeeklyCalendarCard.gd`

Add new node references (absolute paths, consistent with current code style in this script):

- `_week_transition_overlay: ColorRect` → `/root/Control/WeekTransitionOverlay`
- `_monthly_recap_overlay: Control` → `/root/Control/MonthlyRecapOverlay`
- `_monthly_recap_continue: Button` → `/root/Control/MonthlyRecapOverlay/.../ContinueButton`
- Labels/containers for recap:
  - `HeadingLabel`
  - Finance value labels
  - `StatsEmptyLabel`, `StatsList`
  - `EventsEmptyLabel`

Add internal state:

- `_month_start_stats: Dictionary` storing month-start values for:
  - Health, Happiness, Smarts, Looks, Fitness, Stress
- Optional `_month_start_year/_month_start_month_index` to know when to refresh snapshot

Implement weekly transition wrapper:

- Replace the direct `advance_time(1)` call in `_on_next_week_button_pressed()` with:
  1. Capture `old_month_index` and `old_year`
  2. Play fade-out on `_week_transition_overlay` (~0.15–0.25s)
  3. While dark: call `advance_time(1)` (this updates week label + header via `_update_labels()`)
  4. Detect month change: `month_changed = (month_index != old_month_index) or (year != old_year)`
  5. If **no** month change:
     - fade back in and hide `_week_transition_overlay`
  6. If **month changed**:
     - show monthly recap overlay (pauses energy timer) and keep screen dim (do not fade-in yet)

This ensures the week/month labels update during the dark portion of the fade, as requested.

### 4) Monthly recap show/dismiss behavior (script)

**File:** `scripts/WeeklyCalendarCard.gd`

Show recap:

- `set_energy_paused(true)` while recap is visible
- Populate heading as the **month that just ended** (the previous month/year), e.g. if the calendar just advanced into June, recap heading shows “May 2025”
- Populate finances from `/root/Control.player_data` if present:
  - Income = current job salary else 0
  - Expenses = 0
  - End balance = bank_balance
- Populate stat changes:
  - Compare current `player_data` stats vs `_month_start_stats`
  - Add only non-zero deltas (absolute >= 1, or rounded threshold) into `StatsList`
  - If none, show `StatsEmptyLabel`
- Events section:
  - Always show `EventsEmptyLabel` for now (“No major events this month.”)

Dismiss recap (Continue button or ESC):

- Hide `MonthlyRecapOverlay`
- Refresh month-start snapshot to the **new** month’s starting stats
- Resume energy drain: `set_energy_paused(false)`
- Finish the visual: fade `_week_transition_overlay` back to transparent and hide it

Input handling:

- In `WeeklyCalendarCard._input(event)`, add a new top-priority block:
  - If `MonthlyRecapOverlay.visible` and `ui_cancel` (ESC) is pressed → dismiss recap and `return`
  - This prevents conflicting behavior with the existing pause toggle while recap is open.

## Verification Steps

1. **Weekly fade**
   - Deplete energy to 0 and press Space / click Next Week
   - Verify quick fade-out → labels update while dark → fade-in completes
   - Verify input is not locked beyond the fade duration
2. **Monthly recap**
   - Advance weeks until month rolls over (week 4 → week 1)
   - Verify recap overlay appears, dims background, and energy drain pauses
   - Verify heading shows previous month/year
   - Verify Continue button hides overlay and resumes energy drain
   - Verify ESC dismisses recap (and does not open PauseOverlay)
3. **Overlay conflict checks**
   - While recap is visible, press ESC (should dismiss recap, not pause)
   - After recap dismissed, press ESC (should open pause)
   - Ensure DepletedOverlay still works normally and does not get stuck under recap.

