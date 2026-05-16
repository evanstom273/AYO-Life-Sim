## Summary
- Make Energy a first-class UI element by moving it **between the Life Log and the bottom cards row**, as a wide HUD-style bar.
- Fix the “OUT OF ENERGY” popup so it is **always visible** by using a **root-level overlay with a centered card panel**.
- Keep the existing “NextWeekButton” as the interaction to continue, and make the depleted overlay **block input until Next Week**.

## Current State Analysis (Grounded)
- Energy UI currently lives under the Calendar card (`CalendarCard/.../EnergyRow`) in [MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn).
- WeeklyCalendar logic is in [WeeklyCalendarCard.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/WeeklyCalendarCard.gd):
  - On depletion it currently spawns a Label under `/root/Control/ColorRect`, but it is still ending up off-screen/invisible in practice.
  - It hides the energy ProgressBar and shows `NextWeekButton`.
- Pause overlay exists at root as `PauseOverlay` and blocks input.

## Decisions Locked (From You)
- Energy placement: **between log & cards** (center column).
- Energy display: **bar + percent inside the bar**.
- Depleted UI: centered **card panel** and **blocks until Next Week**.
- Proceed action: use the **existing NextWeekButton**, not a separate new button.

## Proposed Changes

### Part A — Energy HUD (MainUI.tscn)
File: [MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn)

1) Create a new Energy HUD section between the Life Log list and the bottom cards row
- Insert a new `PanelContainer` (using the existing `card_dark.tres` style) into:
  - `ColorRect/.../CenterVBox`, positioned:
    - after `ShowMoreContainer`
    - before the bottom cards `HBoxContainer`
- Inside it, add an `HBoxContainer` with:
  - Energy icon (reuse the existing energy icon)
  - A wide `ProgressBar` (thicker, HUD-like)
  - (Optional) remove the separate value label since you want percent inside the bar
- Set the ProgressBar:
  - `show_percentage = true` (percent inside the bar)
  - thicker `custom_minimum_size.y` (target: 24–32px depending on visual fit)

2) Remove the EnergyRow from inside CalendarCard
- Delete the `CalendarCard/.../EnergyRow` so the Calendar card stays focused on time/week controls.

3) Keep NextWeekButton (still hidden by default)
- Decide where it should live for best flow:
  - Preferred: keep it in CalendarCard where it is today (script already references it), but it will be used alongside the new overlay.
  - Alternate: move it into the depleted overlay card so it is visually “attached” to the message.
- In either case, it remains named `NextWeekButton` and starts with `visible = false`.

### Part B — Depleted Overlay (MainUI.tscn)
File: [MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn)

1) Add a new root-level overlay (sibling to PauseOverlay)
- Add `DepletedOverlay` (ColorRect) under the root `Control`:
  - full-screen anchors
  - semi-transparent black (e.g. 35–50% opacity)
  - `visible = false`
  - `mouse_filter = STOP` to block input underneath
- Add a centered `PanelContainer` (card_dark) with:
  - Title label: `OUT OF ENERGY!`
  - Body label: short explanation
  - No separate “OK” button
  - The existing `NextWeekButton` is either placed inside this panel (if we choose to move it), or the overlay will be configured to allow clicking it if it stays elsewhere (not recommended).

### Part C — Script Wiring (WeeklyCalendarCard.gd)
File: [WeeklyCalendarCard.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/WeeklyCalendarCard.gd)

1) Update energy node references to the new HUD bar
- Update `_energy_bar` to point to the new ProgressBar in the Energy HUD.
- Remove or repurpose `_energy_label` (if we no longer show “32 / 100”, it may be unused).

2) Replace the dynamic Label popup with overlay control
- Add `@onready` references to:
  - `DepletedOverlay` (root-level)
  - The overlay’s card panel (for animation)
- In `_on_energy_depleted()`:
  - Hide the Energy HUD ProgressBar
  - Show `NextWeekButton`
  - Show `DepletedOverlay`
  - Animate the overlay’s card panel (scale/alpha pop)
  - Keep the existing screen shake

3) On reset/new week
- In `reset_energy()`:
  - Hide `DepletedOverlay`
  - Hide `NextWeekButton`
  - Show the Energy HUD ProgressBar again
  - Ensure the timer restarts as it does today

4) Pause interaction edge case
- If `DepletedOverlay.visible` is true, ignore ESC pause toggles (so the depleted state remains the priority until Next Week).

## Assumptions & Constraints
- HUD energy bar should only exist/operate on Overview (your existing auto-pause-off-Overview remains).
- The depleted overlay is not an `AcceptDialog`; it is a UI overlay that blocks input until Next Week.

## Verification Steps
- Energy HUD:
  - Energy bar is visually prominent between log and cards.
  - Percent appears inside the bar and updates as energy drains.
- Depletion:
  - When energy hits 0: Energy bar hides, centered depleted card is visible, and the message is not off-screen.
  - Underlying UI is blocked until Next Week.
  - Clicking NextWeekButton advances the week, restores energy, hides overlay, shows energy bar, and resumes drain.
- Pause:
  - ESC pause works normally when not depleted.
  - When depleted overlay is visible, ESC does not open PauseOverlay.
