## Summary
Implement a proper in-game Pause Menu (ESC / gear icon) and a separate Settings overlay that opens on top of the pause menu, persists settings via `ConfigFile`, and applies key settings in real time (display, audio, UI scale, energy drain speed).

## Current State Analysis
- Pause UI is a minimal overlay in [MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn) (`PauseOverlay`) with a single Resume button; pause logic lives in [WeeklyCalendarCard.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/WeeklyCalendarCard.gd) (`toggle_pause`, ESC handling).
- The top-right gear button in [MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn#L1389-L1441) is wired in [MainUI.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/MainUI.gd) to call the calendar card’s `toggle_pause()`.
- Scene switching uses the `SceneTransitions` autoload ([SceneTransitions.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/SceneTransitions.gd)); there is no gameplay save/autosave system yet.
- Godot version is 4.6 (see [project.godot](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/project.godot#L11-L33)).

## Proposed Changes

### 1) Replace PauseOverlay with a proper Pause Menu card
**Files**
- Update scene: [MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn)
- Update behavior: [WeeklyCalendarCard.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/WeeklyCalendarCard.gd)
- Update gear icon behavior: [MainUI.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/MainUI.gd)

**Scene changes (MainUI.tscn)**
- Keep the overlay name `PauseOverlay` (so existing root pathing stays stable) but replace its contents with:
  - Fullscreen semi-transparent background `ColorRect` (same style as monthly recap/pause overlays, e.g. `Color(0,0,0,0.6)`).
  - Centered `PanelContainer` using existing `card_dark.tres`.
  - Title label: `Paused`.
  - Button column:
    - `ResumeButton`
    - `SettingsButton`
    - `MainMenuButton`

**Script changes (WeeklyCalendarCard.gd)**
- Replace the public pause API from `toggle_pause()` to a small explicit API:
  - `open_pause_menu()`, `close_pause_menu()`, `toggle_pause_menu()`
  - `open_settings_overlay()`, `close_settings_overlay()` (delegates to Settings overlay node)
- Update `_input` behavior:
  - If Depleted overlay visible: ignore ESC (existing behavior).
  - If Monthly recap visible: ESC dismisses monthly recap (existing behavior).
  - If Settings overlay visible: ESC closes Settings overlay only (pause menu remains).
  - Else ESC toggles Pause menu.
- Wire pause buttons:
  - ResumeButton → `close_pause_menu()` (unpauses energy drain timer).
  - SettingsButton → `open_settings_overlay()` (keeps pause overlay visible underneath).
  - MainMenuButton → autosave then go to MainMenu scene via `SceneTransitions.go_to("res://scenes/main/MainMenu.tscn")`.

**Script changes (MainUI.gd)**
- Change the gear icon handler to open the pause menu directly (not toggle):
  - `_on_settings_pressed()` calls `open_pause_menu()` on the calendar card if present.

### 2) Add a separate Settings overlay (opens on top of Pause)
**Files**
- Update scene: [MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn)
- Add manager: `res://scripts/SettingsManager.gd` (autoload)
- Update pause/settings integration: [WeeklyCalendarCard.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/WeeklyCalendarCard.gd)
- Update project autoloads: [project.godot](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/project.godot)

**Scene changes (MainUI.tscn)**
- Add a new top-level node `SettingsOverlay` *after* `PauseOverlay` so it draws above it:
  - Fullscreen semi-transparent background (alpha tuned so the pause dim doesn’t become “double-black”; recommended: `Color(0,0,0,0.0)` or `0.15`).
  - Centered `PanelContainer` using `card_dark.tres`.
  - Header row: `BackButton` (← Back) and `Settings` title.
  - `TabContainer` with 5 tabs:
    - Display
    - Audio
    - Gameplay
    - Accessibility
    - Help

**Control layout per tab**
- Display:
  - Fullscreen toggle (CheckButton)
  - Resolution dropdown (OptionButton) with common 16:9 entries: 1280×720, 1600×900, 1920×1080, 2560×1440
  - UI Scale slider (HSlider) range 0.5–2.0, default 1.0, step 0.05
- Audio:
  - Master/Music/SFX volume sliders (0–100) defaults 100/80/80, step 1
  - UI sounds toggle (CheckButton) default on
- Gameplay:
  - Energy Drain Speed slider (0.1–1.0 step 0.05 default 0.40) with helper label “Higher = slower drain”
- Accessibility:
  - Font size dropdown (Small/Medium/Large), default Medium
  - Dyslexia-Friendly Font toggle
  - Reduce Animations toggle
  - Colourblind Mode toggle
- Help:
  - Tooltip hints toggle default on
  - Reset tutorial hints button

**Behavior wiring (WeeklyCalendarCard.gd)**
- On open settings: `SettingsOverlay.visible = true`, keep energy paused (already paused by pause menu).
- On close settings: `SettingsOverlay.visible = false`, return to pause menu state (still paused until Resume).
- Back button (and ESC while settings open) closes settings overlay only.

### 3) Persist settings with ConfigFile + apply in real time
**Files**
- Add: `res://scripts/SettingsManager.gd` (new autoload)
- Update: [project.godot](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/project.godot)
- Update: [WeeklyCalendarCard.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/WeeklyCalendarCard.gd) (energy drain binding)
- Update: [UIAnimator.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/UIAnimator.gd) (reduce animations)

**SettingsManager design**
- Config path: `user://settings.cfg`
- Defaults (decision):
  - display.fullscreen=false
  - display.resolution="1280x720"
  - display.ui_scale=1.0
  - audio.master=100, audio.music=80, audio.sfx=80, audio.ui_sounds=true
  - gameplay.energy_drain_speed=0.40
  - accessibility.font_size="medium", dyslexia_font=false, reduce_animations=false, colourblind_mode=false
  - help.tooltip_hints=true
- API:
  - `load_settings()`, `save_settings()`
  - `get_value(section: String, key: String, default)`
  - `set_value(section: String, key: String, value)` (writes + saves + emits `setting_changed(section,key,value)`)
  - `apply_all()` called on `_ready()` of autoload to apply at boot.

**Real-time application rules**
- Display:
  - Fullscreen/windowed via `DisplayServer.window_set_mode(...)`.
  - Resolution via `DisplayServer.window_set_size(Vector2i(...))` when windowed.
  - UI scale via `get_tree().root.get_window().content_scale_factor = ui_scale`.
- Audio:
  - Apply volume to buses by converting 0–100 to dB and calling `AudioServer.set_bus_volume_db(bus_idx, db)`.
  - UI sounds toggle is stored; actual UI SFX can hook later.
- Gameplay:
  - `gameplay.energy_drain_speed` drives `WeeklyCalendarCard.energy_tick_rate`.
  - `WeeklyCalendarCard._ready()` reads from SettingsManager and connects to `setting_changed` to update live.
- Accessibility:
  - Font size maps to `ThemeDB.fallback_font_size` values (Small=14, Medium=16, Large=18).
  - Dyslexia-friendly font swaps `ThemeDB.fallback_font` between Inter and OpenDyslexic at runtime.
  - Reduce animations: `UIAnimator._anim_to` sets properties instantly (no tween) when enabled; any other tweens can optionally check the same setting later.
  - Colourblind mode is persisted; initial implementation will not remap all UI colors, but will be available for future palette switches.
- Help:
  - Tooltip hints persisted.
  - Reset tutorial hints: implemented as a stub that clears a future `user://tutorial_hints.cfg` file if present (no current tutorial system exists).

### 4) Create audio bus layout for Master/Music/SFX
**Files**
- Add: `res://audio/bus_layout.tres` (new)
- Update: [project.godot](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/project.godot) to point `audio/buses/default_bus_layout` at the new layout.

**Bus layout**
- Buses (in order): Master, Music (send to Master), SFX (send to Master)
- SettingsManager uses these names to find the correct bus indices.

### 5) Implement “autosave before Main Menu”
**Files**
- Add: `res://scripts/SaveGame.gd` (new)
- Update: [WeeklyCalendarCard.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/WeeklyCalendarCard.gd) (Main Menu button handler)

**Autosave scope (minimal but useful)**
- Write `user://autosave.cfg` using `ConfigFile` with:
  - time: year, month_index, week_index, current_energy
  - player: person_name, person_age, person_gender, birth_month, bank_balance, stats (Health/Happiness/Smarts/Looks/Fitness/Stress), highest_education_completed
  - job (if any): job_name, company_name, salary
- No load/continue wiring in this task (the Load/Continue flow remains unchanged); this satisfies “autosaves before returning to main menu” without expanding scope.

### 6) Add dyslexia-friendly font asset
**Files**
- Add font file: `res://assets/fonts/OpenDyslexic-Regular.ttf`
- Add accompanying license file in `res://assets/fonts/` (matching upstream license requirements).

## Assumptions & Decisions
- Settings overlay background alpha will be tuned so it does not “double dim” when stacked above the pause overlay (default planned: 0.0–0.15).
- Resolution dropdown uses a curated set of common 16:9 options (not a platform-specific enumeration).
- Colourblind mode persists but does not yet remap all UI accent colors (kept in scope for later palette work).
- Tutorial hints system does not exist yet; Reset Tutorial Hints will clear a placeholder file / in-memory flags for future integration.

## Verification Steps
- In-game:
  - Press ESC: Pause menu appears; energy drain stops; Resume resumes drain.
  - Click gear icon: opens Pause menu (same as ESC).
  - Click Pause → Settings: Settings overlay appears above Pause; ESC/Back returns to Pause (still paused).
  - Click Main Menu: autosave file appears in `user://autosave.cfg`, then scene transitions to MainMenu.
- Settings persistence:
  - Change UI Scale / fullscreen / resolution / energy drain speed / volumes; restart game; values persist and reapply.
- Audio:
  - Confirm `AudioServer` buses exist (Master/Music/SFX) and slider changes update bus volume dB.
- Reduce animations:
  - Toggle on: button hover/press animations stop (instant state).
