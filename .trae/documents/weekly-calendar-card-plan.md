# Weekly Calendar Card (Plan)

## Summary
Turn the existing empty `CalendarCard` in `MainUI.tscn` into a compact weekly calendar UI that shows the current month/year and 4 week “pills” (Wk1–Wk4). Weeks are clickable; selection is local UI state (no gameplay time system yet).

## Current State Analysis (Repo Truth)
- The target node already exists but is empty:
  - `ColorRect/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/PanelContainer/CenterMargin/CenterVBox/HBoxContainer/CalendarCard`
  - Defined in [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn#L1360-L1368) as a `PanelContainer` with `panel1.tres` styling.
- There is no current game-time/week system in scripts; MainUI is largely static UI scaffolding.
- The UI already uses local `StyleBoxFlat` subresources and `theme_override_*` patterns extensively in `MainUI.tscn`.

## Decisions (From You)
- Weeks mapping: **4 weeks per month** (Jan Wk1–Wk4, etc.; 48-week year model).
- Layout: **Month + week pills**.
- Interaction: **Clickable weeks** (one selected at a time).
- Current week source: **Placeholder value** (hardcoded starting month/year/week for now).

## Proposed Changes

### 1) Build out `CalendarCard` node contents (scene-only UI)
**File:** `scenes/main/MainUI.tscn`

Add children under `CalendarCard`:
- `MarginContainer` (padding ~16)
  - `VBoxContainer` (separation ~10–12)
    - `Header` (`HBoxContainer`)
      - Left: `Label` “Calendar” (font_size ~16)
      - Spacer `Control` (expand)
      - Right: `Label` “Jan 2025” (secondary text color, font_size ~12–13)
    - `WeeksRow` (`HBoxContainer`, separation ~8)
      - Four `Button` nodes: `Wk1`, `Wk2`, `Wk3`, `Wk4`
        - `toggle_mode = true`
        - Use a shared `ButtonGroup` so only one week is active at a time
        - Default selected: `Wk1` pressed
    - Optional small helper line (only if it fits cleanly): `Label` “Jan – Wk1” (secondary text)

This keeps hierarchy minimal and aligns with existing panel-card patterns already used in the scene.

### 2) Add local StyleBox subresources for “week pill” buttons
**File:** `scenes/main/MainUI.tscn`

Define new `StyleBoxFlat` subresources near the top of the scene (next to existing nav/filter StyleBoxes):
- `StyleBoxFlat_week_pill_normal`
  - Transparent or very subtle bg
  - 1px border (match existing light border color used elsewhere)
  - Rounded corners ~10–12
  - Content margins ~10×6
- `StyleBoxFlat_week_pill_hover`
  - Slightly darker light bg (like existing hover surfaces)
- `StyleBoxFlat_week_pill_selected`
  - Background: reuse the “selected” light color already present in the project (`LIGHT_SELECTED_BG` equivalent used in active rows), so it also maps correctly under the runtime DarkMode system
  - Border color: reuse the existing accent blue used in MainUI

Apply these via per-button theme overrides:
- `theme_override_styles/normal = week_pill_normal`
- `theme_override_styles/hover = week_pill_hover`
- `theme_override_styles/pressed = week_pill_selected`
- Text/icon colors: match existing primary text; for selected state use accent blue (similar to sidebar active row).

### 3) Keep it placeholder-only (no new time progression code)
- Month/year text remains hardcoded to “Jan 2025” for now.
- Week selection is purely visual state driven by toggle buttons + group.
- No coupling to AgeUp or other actions yet.

## Assumptions & Constraints
- Only change the `CalendarCard` (add children and local style subresources) and do not restructure the rest of MainUI.
- Weekly calendar is an abstraction (4 weeks/month) and not a real-world date model at this stage.
- Dark mode already exists; keeping “selected” styling aligned with existing light selected colors helps the runtime mapper apply dark selected backgrounds consistently.

## Verification
- Open `MainUI.tscn` and confirm `CalendarCard` now shows:
  - Header “Calendar” + “Jan 2025”
  - Four week pills Wk1–Wk4
- Click Wk2/Wk3/Wk4 and confirm only one stays selected (ButtonGroup behavior).
- Run diagnostics check (no scene parse errors, no missing resources).
