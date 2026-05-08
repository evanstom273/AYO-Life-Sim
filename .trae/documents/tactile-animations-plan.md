# Tactile UI Animations (Plan)

## Summary
Add snappy, modern “tactile” feedback to UI controls (hover/press/focus) across all scenes, and add a fade + slight zoom scene transition for all menu-driven scene switches.

## Current State Analysis (Repo Truth)
- Scenes:
  - Main menu: [MainMenu.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainMenu.tscn)
  - Placeholders: [NewGame.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/NewGame.tscn), [LoadGame.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/LoadGame.tscn), [Settings.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/Settings.tscn)
  - In-game UI: [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn)
- Scene switching currently happens only in:
  - [MainMenu.gd](file:///c:/Users/evans/Documents/text-based-life-sim/scripts/MainMenu.gd) via `get_tree().change_scene_to_file(...)`
  - [MenuPlaceholder.gd](file:///c:/Users/evans/Documents/text-based-life-sim/scripts/MenuPlaceholder.gd) via `get_tree().change_scene_to_file(...)`
- No Tween/AnimationPlayer usage exists yet (visual feedback is mostly theme StyleBox hover/pressed swaps).
- There is already an autoload in [project.godot](file:///c:/Users/evans/Documents/text-based-life-sim/project.godot): `GlobalShortcuts` for F11 fullscreen.

## Decisions (From You)
- Scene transitions: **Fade + slight zoom**
- Button feel: **Snappy**
- Scope: **All UI buttons** (Buttons, OptionButtons, CheckBoxes, MenuButtons, etc.)
- Reduce Motion toggle: **No**

## Proposed Changes

### 1) Add a global scene transition manager (fade + slight zoom)
**New file:** `scripts/SceneTransitions.gd`

**Why:** Centralizes the transition effect so every scene switch feels consistent and “tactile”.

**Implementation details:**
- Autoload `SceneTransitions` (added in `project.godot`).
- On `_ready`, create an overlay `CanvasLayer` with a full-screen `ColorRect`:
  - Starts transparent (`color.a = 0`)
  - Anchors preset full-rect
  - Z above gameplay UI so it cleanly covers everything during transitions
- Public API:
  - `go_to(scene_path: String) -> void`
  - Optional: `go_to_quiet(scene_path: String)` if needed later, but not required for this task
- Behavior of `go_to`:
  1) Guard re-entry (`_is_transitioning` flag).
  2) Fade overlay alpha 0 → 1 quickly (snappy, ~0.10–0.14s, eased).
  3) Change scene via `get_tree().change_scene_to_file(scene_path)`.
  4) Wait 1 frame so new scene is instanced, then if `get_tree().current_scene` is a `Control`:
     - Set `pivot_offset = scene.size * 0.5` (after layout)
     - Set `scale = Vector2(0.98, 0.98)`
     - Tween `scale` to `Vector2(1, 1)` over ~0.12–0.16s (ease out)
  5) Fade overlay alpha 1 → 0 over ~0.12–0.16s in parallel with the zoom-in.

**Files to update:**
- `scripts/MainMenu.gd`: replace direct `change_scene_to_file` with `SceneTransitions.go_to(path)`
- `scripts/MenuPlaceholder.gd`: replace back navigation with `SceneTransitions.go_to(back_scene_path)`

### 2) Add global tactile animations for all buttons
**New file:** `scripts/UIAnimator.gd`

**Why:** Avoids per-scene scripts and makes every button feel responsive.

**Implementation details:**
- Autoload `UIAnimator` (added in `project.godot`).
- Connect to `get_tree().node_added` and configure any node that is a `BaseButton`:
  - One-time setup guard (use `set_meta("ui_anim_hooked", true)`).
  - Keep per-button tweens in a dictionary keyed by `instance_id` so animations don’t fight:
    - On new animation, kill the existing tween first.
  - Ensure scaling feels centered:
    - Set `pivot_offset = button.size * 0.5` and update on `resized` signal.
- Snappy motion values:
  - Hover/focus target scale: `1.04`
  - Press target scale: `0.96`
  - Durations: ~0.06–0.10s with ease out
  - Optional subtle “brightness” on hover using `self_modulate` (e.g., `Color(1.04, 1.04, 1.04, 1)`), returning to white on exit.
- Signal wiring per button:
  - `mouse_entered` → animate to hover scale (unless pressed)
  - `mouse_exited` → animate back to 1.0 (unless pressed)
  - `button_down` → animate to pressed scale
  - `button_up` → animate to hover scale if hovered, else back to 1.0
  - `focus_entered` / `focus_exited` → same as hover/exit (for keyboard/controller)
- Disabled buttons:
  - If `button.disabled`, skip applying hover/press animation and ensure scale stays at 1.0.

**Notes on scope:**
- This applies automatically to buttons across:
  - MainMenu, placeholders, MainUI (including sidebar buttons, quick actions, checkboxes, filters OptionButton, etc.)
- Theme hover/pressed StyleBoxes remain; the tactile scale/brightness complements them.

### 3) Register the new autoloads
**File to update:** `project.godot`

**Change:**
- Under `[autoload]`, add:
  - `SceneTransitions="*res://scripts/SceneTransitions.gd"`
  - `UIAnimator="*res://scripts/UIAnimator.gd"`
- Keep the existing `GlobalShortcuts` entry as-is.

## Assumptions & Constraints
- All current scene roots are `Control` (true for current scenes), enabling zoom effect on transition.
- No “Reduce Motion” option is added (per decision).
- Keep changes focused to animation/transition behavior; no UI layout redesigns.

## Verification
- Launch the project (starts at MainMenu) and confirm:
  - Hover and press on every button visibly scales/snaps (MainMenu, placeholder scenes, MainUI).
  - Scene switches (Continue/New Game/Load Game/Settings/Back) use fade + slight zoom consistently.
  - F11 fullscreen continues to work in all scenes (autoload still active).
- Sanity check for regressions:
  - No console errors when hovering/pressing buttons rapidly.
  - No stuck “scaled” buttons after scene transitions.
