## Summary
- Make the **Life Goals** checkboxes feel like real “buttons” (same vibe as **Quick Actions** / **Calendar**), with full-width clickable rows and a clear filled “checked” state.
- Add a **blue accent that’s always visible** to **Quick Actions** + **Calendar** buttons (blue border + blue icon accents, but keep label text white).

## Current State Analysis (Grounded)
- Life Goals live in the left sidebar card:
  - `LifeGoalsCard` at `ColorRect/MarginContainer/VBoxContainer/HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/LifeGoalsCard` ([MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn#L2775-L2914))
  - Goals are `CheckBox` nodes: `Goal1..Goal4` under `.../LifeGoalsCard/.../Goals` ([MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn#L2806-L2897))
  - These CheckBoxes currently only override focus style and check/uncheck icons; they don’t have button-like backgrounds, so they read “flat”.
- Quick Actions buttons are already styled as buttons, but the accent is mostly hover/focus:
  - `QuickActionsCard/Grid` contains `Study`, `WorkHard`, `GoToDoctor`, `CallFriend`, `BrowseJobs` ([MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn#L3670-L3839))
  - Each one uses per-button StyleBoxFlat subresources (e.g. `theme_override_styles/normal = SubResource("StyleBoxFlat_rknwy")` etc.), and icon hover/focus colors already reference the blue accent.
- Calendar card buttons include:
  - Month controls: `PrevMonth`, `NextMonth` ([MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn#L3879-L3929))
  - Week toggles: `Wk1..Wk4` (toggle buttons with `ButtonGroup_calendar_weeks`) ([MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn#L3938-L4012))
  - Actions: `NextWeekBtn`, `SkipMonthBtn` (and the “Skip Year” button which is also named `SkipMonthBtn`) ([MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn#L4058-L4137))

## Decisions Locked (From You)
- Life Goals:
  - Make them **full-width button rows**.
  - Checked state: **filled highlight** with a **strong blue** feel.
  - Style source: **same as Quick Actions**.
  - Checkbox stays (no extra icons).
  - Single accent color: **blue**.
- Quick Actions + Calendar:
  - Apply **blue accent always**.
  - Keep **label text white**.
  - Apply to **all Calendar buttons** (month arrows, Wk1–Wk4, Next Week, Skip Month, Skip Year).

## Proposed Changes

### 1) Introduce shared “Accent Button” StyleBoxes (avoid per-button drift)
File: [MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn)
- Add new `StyleBoxFlat` subresources dedicated to action buttons:
  - `ActionBtnNormal`: dark bg, **blue border**, rounded corners, comfortable content margins
  - `ActionBtnHover`: slightly lighter bg (still dark), **blue border**
  - `ActionBtnPressed`: **filled selected/blue** bg with blue border
  - `ActionBtnDisabled`: muted bg + muted border
- Rationale: Right now each button points to its own StyleBoxFlat id; this makes it hard to keep consistent.

### 2) Apply “Accent Button” style to Quick Actions buttons
File: [MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn)
- For `Study`, `WorkHard`, `GoToDoctor`, `CallFriend`, `BrowseJobs`:
  - Replace `theme_override_styles/normal/hover/pressed/disabled/focus` with the new shared StyleBoxes.
  - Set colors so the accent is visible even when not hovered:
    - `font_color` stays white
    - `icon_normal_color` becomes blue (and keep hover/pressed consistent)

### 3) Apply “Accent Button” style to Calendar buttons
File: [MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn)
- Month arrow buttons: `PrevMonth`, `NextMonth`
  - Use the shared StyleBoxes.
  - Keep arrow text white; rely on the **blue border** for the always-on accent.
- Week toggles: `Wk1..Wk4`
  - Use the shared StyleBoxes.
  - Keep `toggle_mode = true` and existing `ButtonGroup_calendar_weeks`.
  - Ensure pressed/toggled state uses `ActionBtnPressed` (filled blue).
- Action buttons: `NextWeekBtn`, `SkipMonthBtn` (both instances; one is the “Skip Year” label)
  - Use the shared StyleBoxes.
  - Keep label text white; icons blue-accented.

### 4) Restyle Life Goals CheckBoxes as full-width “button rows”
File: [MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn)
- For `Goal1..Goal4`:
  - Set `custom_minimum_size = Vector2(0, 36)` (matching Quick Actions)
  - Set `alignment = 0` (left aligned)
  - Apply the same shared StyleBoxes:
    - normal → `ActionBtnNormal`
    - hover → `ActionBtnHover`
    - pressed (checked) → `ActionBtnPressed`
    - disabled → `ActionBtnDisabled`
  - Set checkbox icon tint so the “checkbox” reads as a control:
    - `icon_normal_color` blue
    - `font_color` white
  - Keep existing checked/unchecked textures (don’t change goal text or structure).

## Assumptions & Constraints
- Only UI styling/feel changes; no gameplay logic changes.
- Keep the Life Goals items as `CheckBox` nodes (so the checked state stays correct).
- Avoid renaming nodes (e.g., the “Skip Year” button name mismatch) unless explicitly requested.
- Avoid changes outside [MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn).

## Verification Steps
- Open [MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn) in Godot and verify:
  - Life Goals rows look and feel like buttons (hover/pressed background), and checked state is clearly filled/blue.
  - Quick Actions buttons have a visible blue accent even when idle (blue border + blue icons), with white label text.
  - Calendar buttons (month arrows, weeks, next/skip buttons) have the same always-on blue accent and selected week is clearly filled.
  - No unrelated UI elements change.
