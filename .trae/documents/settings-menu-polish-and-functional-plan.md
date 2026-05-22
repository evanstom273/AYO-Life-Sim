## Summary
Polish the Pause/Settings UI (bigger, cleaner layout) and make every Settings option apply correctly in real time, including font size + dyslexia font. Improve the Energy Drain Speed display to show real “seconds per week”.

## Current State Analysis (Repo Grounding)
- The Settings overlay scene exists in [MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn#L4299-L4499), but its node structure does **not** match the paths used by [WeeklyCalendarCard.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/WeeklyCalendarCard.gd#L63-L120) (the script still looks for `.../MarginContainer/...` inside SettingsOverlay, but the scene currently has `PanelContainer/VBoxContainer` directly). This makes many settings UI references `null`, so changes won’t apply.
- Font settings are applied via `ThemeDB.fallback_font` / `ThemeDB.fallback_font_size` in [SettingsManager.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/SettingsManager.gd#L84-L122), but the project also sets `[gui] theme/default_font` and many UI nodes use explicit `theme_override_font_sizes/font_size`, so changing accessibility font size and dyslexia font may not visibly affect most UI.
- Energy Drain Speed currently shows only “Higher = slower drain” ([MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn#L4436-L4455)), not an actual seconds/week indicator.
- Settings overlay size is mixed (`PanelContainer.custom_minimum_size = Vector2(900, 300)` and child VBox is `Vector2(720, 0)`), with no dedicated inner padding container, so the menu looks cramped compared to the other overlays.

## Proposed Changes

### 1) Fix SettingsOverlay scene structure + make it larger / cleaner
**File:** [MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn)

- Insert a `MarginContainer` inside `SettingsOverlay/CenterContainer/PanelContainer` so the content has consistent padding (match Pause/Monthly recap card style).
- Make the settings card larger and more readable:
  - Increase `PanelContainer.custom_minimum_size` (e.g. 980×560).
  - Increase title font size and tab spacing.
  - Ensure TabContainer fills remaining height (`size_flags_vertical = EXPAND_FILL`).
- Ensure the node paths match what the controlling script will use (either by updating the scene to match the script or updating the script to match the scene). Recommended: add the `MarginContainer` in-scene and standardize to:
  - `SettingsOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/...`

### 2) Make “Energy Drain Speed” show real seconds/week
**Files:**
- [MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn)
- [WeeklyCalendarCard.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/WeeklyCalendarCard.gd)

- Add a dedicated label under (or beside) the slider, e.g. `EnergySpeedValueLabel`.
- Compute seconds/week as:
  - `seconds_per_week = energy_tick_rate * max_energy` (max_energy is 100 in WeeklyCalendarCard)
- Update label live on:
  - initial settings UI init
  - slider changes
  - settings manager change signals
- Display example: `40.0s per week` (or rounded `40s per week`).

### 3) Make font size and dyslexia font visibly apply across the UI
**Files:**
- [SettingsManager.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/SettingsManager.gd)
- (Optional) new helper script: `res://scripts/FontApplier.gd` (if needed to keep SettingsManager lean)

**Dyslexia font**
- Apply the chosen font in a way that overrides the project default font:
  - Set `ProjectSettings.set_setting("gui/theme/default_font", font_path)` at runtime based on config.
  - Also set `ThemeDB.fallback_font` as a secondary safety net.
- Force UI refresh after change:
  - Use `get_tree().root.propagate_notification(Control.NOTIFICATION_THEME_CHANGED)` (or equivalent) so existing controls redraw with the new font.

**Font size**
- Keep `ProjectSettings.set_setting("gui/theme/default_font_size", size)` + `ThemeDB.fallback_font_size = size`.
- Additionally, for controls that have explicit font size overrides, apply a global multiplier so the setting is visible:
  - Store each Control’s “base font size” once (metadata) and reapply with a multiplier:
    - Small: 0.9
    - Medium: 1.0
    - Large: 1.15
  - Apply via `add_theme_font_size_override("font_size", scaled_size)` for Labels/Buttons/RichTextLabels/TabContainer tabs where possible.
- Apply this pass to `/root/Control` so it affects the game UI, not just the settings menu.

### 4) Ensure every settings control actually saves + applies
**Files:**
- [WeeklyCalendarCard.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/WeeklyCalendarCard.gd)
- [SettingsManager.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/SettingsManager.gd)

- Update WeeklyCalendarCard’s `@onready` node paths to match the final `SettingsOverlay` scene hierarchy (this is the primary “settings not working” root cause).
- Add two UX correctness behaviors:
  - Disable the Resolution dropdown while Fullscreen is enabled (and re-enable it when windowed).
  - Initialize dropdown selections using the saved settings, not default values.

### 5) Pause menu size polish (minor)
**File:** [MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn)

- Increase Pause card width slightly and adjust vertical spacing so it matches the Settings card style (title font size, button sizes).

## Assumptions & Decisions
- “Seconds/week” refers to real-time seconds it takes energy to drain from 100 → 0 at 1 energy per tick with `Timer.wait_time = energy_tick_rate`.
- Font size setting is expected to be visibly noticeable across most of the UI, including elements with manually overridden font sizes; this plan implements a safe scaling pass rather than trying to remove overrides from the scene files.

## Verification Steps
- Open Settings and confirm each control changes the game immediately:
  - Fullscreen toggles window mode; Resolution changes window size in windowed mode.
  - UI Scale changes immediately.
  - Font size visibly changes UI text sizing across the main UI.
  - Dyslexia font visibly swaps (Inter ↔ OpenDyslexic) without needing restart.
  - Energy Drain Speed updates both behavior and the seconds/week label.
- Restart game and confirm settings persist via `user://settings.cfg`.
- Confirm no script errors via editor diagnostics.
