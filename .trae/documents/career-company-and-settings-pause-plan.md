# Plan: Career Company + Settings Pause Wiring

## Summary

Implement two UI/data integration fixes:

1. Career panel company label should show the player’s employer company name when employed, otherwise show “Unemployed”.
2. The top-right Settings (gear) button should trigger the same pause behavior as pressing ESC (show PauseOverlay and pause the energy drain timer).

## Current State Analysis

### Career company label

- The Career card in [MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn#L3920-L3956) has a `Company` label under:
  - `ColorRect/.../RightBar/.../CareerCard/.../TopRow/JobInfo/Company`
  - It is currently hardcoded in the scene text to `"BrightWave Agency"`.
- `player_data` is a `PeopleResource` (defined in `scripts/data/PersonData.gd`) and has `current_job: JobResource`, but **no company field exists** in:
  - [PersonData.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/data/PersonData.gd)
  - [JobData.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/data/JobData.gd)
- `MainUI.gd` currently populates job title and other labels in `_init_from_player_data()`, but does not touch the Career `Company` label.

### Settings (gear) pause wiring

- The Settings button exists at:
  - `ColorRect/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer2/Options/SettingsButton` ([MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn#L1419-L1441))
- ESC pause behavior is implemented inside `WeeklyCalendarCard.gd` via `_input(event)`:
  - toggles `_pause_overlay.visible`
  - calls `set_energy_paused(new_paused)` ([WeeklyCalendarCard.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/WeeklyCalendarCard.gd#L123-L148))
- `MainUI.gd` currently does not reference `PauseOverlay` or SettingsButton.

## Assumptions & Decisions

- Company name will be stored on the job resource:
  - Add `@export var company_name: String = ""` to `JobResource` in `scripts/data/JobData.gd`. (Per your selection.)
- When unemployed or company is blank, the Career panel company label should show `"Unemployed"`. (Per your selection.)
- Settings button pause will be implemented by exposing a reusable pause toggle API on `WeeklyCalendarCard.gd` and calling it from `MainUI.gd`, so the Settings button uses the exact same pause logic as ESC.

## Proposed Changes

### 1) Add company_name to JobResource

**File:** `scripts/data/JobData.gd`

- Under `@export_group("Job Info")`, add:
  - `@export var company_name: String = ""`

This is a small schema extension that lets `player_data.current_job.company_name` drive the UI.

### 2) Populate Career company label in MainUI

**File:** `scripts/MainUI.gd`

- Add onready reference for the company label:
  - `$ColorRect/.../CareerCard/.../TopRow/JobInfo/Company`
- In `_init_from_player_data()`:
  - Determine employment using the same logic used for job title:
    - If `player_data.current_job == null` or job title resolves to `"Unemployed"`, treat as unemployed.
  - If employed and `player_data.current_job.company_name.strip_edges()` is non-empty → set company label to it.
  - Otherwise → set company label text to `"Unemployed"`.

### 3) Wire Settings button to pause toggle

**Files:** `scripts/MainUI.gd`, `scripts/WeeklyCalendarCard.gd`

- In `WeeklyCalendarCard.gd`:
  - Add a public method that encapsulates the existing ESC pause toggle behavior:
    - `func toggle_pause() -> void` (or `func set_pause_overlay(open: bool) -> void`)
  - Update `_input(event)` to call that method when `"ui_cancel"` is pressed, instead of duplicating the logic inline.
- In `MainUI.gd`:
  - Add onready reference to `SettingsButton`.
  - Connect `SettingsButton.pressed` in `_ready()` to call the calendar card’s pause toggle:
    - `if _calendar_card != null and _calendar_card.has_method("toggle_pause"): _calendar_card.call("toggle_pause")`

## Verification Steps

1. **Company label**
   - Set up a `PeopleResource` with `current_job` assigned:
     - Set `job_name` and `company_name`
   - Run `MainUI.tscn` and confirm the Career card shows the company name instead of “BrightWave Agency”.
   - Set `current_job = null` (or clear job name / company name) and confirm the company label shows “Unemployed”.
2. **Settings pause**
   - In Overview, click the gear button:
     - PauseOverlay becomes visible
     - Energy drain pauses (timer paused)
     - Resume button works and unpauses
   - Press ESC and confirm it still toggles pause identically.

