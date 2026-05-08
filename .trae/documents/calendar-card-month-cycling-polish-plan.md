# CalendarCard Month Cycling + Polish (Plan)

## Summary
Upgrade `CalendarCard` in `MainUI.tscn` from a basic static layout into a more “filled” card with:
- Month cycling controls (Prev/Next) that wrap the year (Dec→Jan increments year; Jan→Dec decrements year)
- Week pills that expand to fill width
- Cleaner spacing/typography so the card uses available room
- Local placeholder state (starts at **Jan 2025**, resets to **Wk1** on month change)

## Current State Analysis (Repo Truth)
- `CalendarCard` exists at:
  - `ColorRect/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/PanelContainer/CenterMargin/CenterVBox/HBoxContainer/CalendarCard`
  - It’s a `PanelContainer` using `panel1.tres` via `theme_override_styles/panel` in [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn#L1410-L1413).
- It currently contains:
  - Header labels (“Calendar”, “Jan 2025”)
  - `WeeksRow` with Wk1–Wk4 toggle buttons (ButtonGroup)
  - Helper label “Jan • Wk1”
  - See [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn#L1410-L1508).
- There is no gameplay time system wired to UI yet (calendar is placeholder-only by design).

## Decisions (From You)
- Year behavior when cycling months: **Wrap year**
- Month label format: **Jan 2025**
- Week layout: **Fill available width**
- Week selection on month change: **Reset to Wk1**

## Proposed Changes

### 1) Improve CalendarCard layout to use space better
**File:** `scenes/main/MainUI.tscn`

**Changes inside CalendarCard:**
- Add `custom_minimum_size.y` for `CalendarCard` so it feels like a real card (e.g., 140–180 depending on what fits best with the row).
- Increase padding slightly if needed (keep current MarginContainer padding 16, but allow separation to breathe).
- Replace `WeeksRow` from `HBoxContainer` → `GridContainer` with:
  - `columns = 4`
  - `h_separation` ~8–10
  - Each week pill button gets `size_flags_horizontal = 3` so all four pills expand equally.
- Increase week pill readability:
  - `theme_override_font_sizes/font_size` ~13–14 for week buttons
  - `custom_minimum_size.y` ~32–36 for week buttons

**Header restructure (month controls):**
- Keep left `Title` = “Calendar”
- On the right, replace the single `MonthLabel` with a compact month control group:
  - `PrevMonth` button (text “‹”, flat, small square)
  - `MonthLabel` (“Jan 2025”)
  - `NextMonth` button (text “›”, flat, small square)

This stays scene-native (no layout changes elsewhere in MainUI), but makes the card feel intentional and scaled.

### 2) Add a tiny controller script for month/week state (placeholder-only)
**New file:** `scripts/WeeklyCalendarCard.gd`

**Attach to:** `CalendarCard` in `MainUI.tscn`

**Responsibilities:**
- Store placeholder state:
  - `year = 2025`
  - `month_index = 0` (Jan)
  - `week_index = 1..4` (starts at 1)
- Update UI:
  - `MonthLabel` text → “Jan 2025” etc.
  - `Helper` text → “Jan • Wk1” etc.
- Handle input:
  - `PrevMonth.pressed` / `NextMonth.pressed`:
    - Update month_index (+/-), wrap year at ends
    - Reset week selection to Wk1 (set Wk1 pressed)
    - Refresh labels
  - Week button pressed/toggled:
    - Update helper label immediately

**Implementation notes (avoid brittle % lookups):**
- Use explicit node paths relative to `CalendarCard` (e.g., `get_node("MarginContainer/VBoxContainer/...")`).
- Avoid any dependency on other systems (no save, no game clock, no autoloads).

### 3) Style tweaks for month nav buttons and week pills
**File:** `scenes/main/MainUI.tscn`

- Reuse existing light-mode colors already present in the UI so DarkMode mapping keeps working:
  - Selected background uses the existing light selected color
  - Accent uses the existing light accent blue
- Month nav buttons:
  - Use existing `StyleBoxFlat_filters_normal/hover` (or add a small dedicated StyleBox if needed) so they match other mini buttons.

## Assumptions & Constraints
- This is a UI-only calendar: it represents a simplified 4-weeks-per-month model (48-week year), no real dates.
- Only touches `CalendarCard` subtree + adds one small script file; no changes to broader MainUI layout.

## Verification
- Open `MainUI.tscn`:
  - CalendarCard fills space better and week pills stretch evenly.
  - Prev/Next month buttons are visible and aligned.
- Run the game and click:
  - Next: Jan 2025 → Feb 2025 (… Dec 2025 → Jan 2026)
  - Prev: Jan 2025 → Dec 2024
  - Month change resets selection to Wk1.
  - Clicking Wk2/Wk3/Wk4 updates the helper text.
- Diagnostics are clean (no script compile errors, no missing nodes).
