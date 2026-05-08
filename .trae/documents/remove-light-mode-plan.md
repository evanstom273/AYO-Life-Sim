## Summary

Remove light mode behavior so the game is always in dark mode at runtime (no toggle), rely on the DarkMode autoload to apply the dark palette everywhere, and remove editor ThemePreview support from scenes.

## Current State Analysis (From Repo)

- Main scene is [MainMenu.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainMenu.tscn) via [project.godot](file:///c:/Users/evans/Documents/text-based-life-sim/project.godot#L11-L24).
- DarkMode is an autoload singleton: [project.godot](file:///c:/Users/evans/Documents/text-based-life-sim/project.godot#L18-L24).
- DarkMode currently:
  - Initializes `_palette` from `config.light` by default ([DarkMode.gd](file:///c:/Users/evans/Documents/text-based-life-sim/scripts/DarkMode.gd#L48-L63)).
  - Provides a Ctrl+D toggle via `_unhandled_key_input()` and `toggle()` that flips between `config.dark` and `config.light` ([DarkMode.gd](file:///c:/Users/evans/Documents/text-based-life-sim/scripts/DarkMode.gd#L80-L110)).
  - Only applies the theme when `active == true`; `active` is set in `toggle()` ([DarkMode.gd](file:///c:/Users/evans/Documents/text-based-life-sim/scripts/DarkMode.gd#L112-L117)).
- ThemePreview (editor-only theming) is present as a node in multiple scenes (example: [MainMenu.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainMenu.tscn#L615-L618), [Settings.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/Settings.tscn#L18-L21)).

## Decisions (From Your Answers)

- Runtime: Always dark; remove/disable the toggle.
- Cleanup: Disable only (no deletion of light resources required).
- Editor: Remove ThemePreview entirely.
- Scenes: Do not bake dark colors into scenes; rely on DarkMode to apply dark palette.

## Proposed Changes

### 1) Make DarkMode always-on and dark-only (no toggle)

Update [DarkMode.gd](file:///c:/Users/evans/Documents/text-based-life-sim/scripts/DarkMode.gd):

- In `_ready()`:
  - Load `ThemeConfig` as it does today.
  - Set `active = true`.
  - Set `dark_enabled = true`.
  - Set `_palette = _config.dark` (fallback to existing behavior only if null).
  - Generate checkbox textures for the dark palette.
  - Run an initial `_scan(get_tree().root)` so all scenes start dark immediately.
- Remove (or no-op) runtime toggle wiring:
  - Remove `_unhandled_key_input()` handler and the Ctrl+D shortcut.
  - Remove `toggle()` (or keep it private but unused); ensure no remaining references.

Why this matches “rely on DarkMode”:
- Scenes can remain with mixed/hardcoded colors; DarkMode already restores + applies per node and hooks `node_added` for newly-instanced UI ([DarkMode.gd](file:///c:/Users/evans/Documents/text-based-life-sim/scripts/DarkMode.gd#L70-L128)).

### 2) Remove ThemePreview nodes from scenes (editor preview removed)

Update scenes to remove ThemePreview usage entirely:

- [MainMenu.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainMenu.tscn):
  - Remove the `ThemePreview` node block.
  - Remove the `ext_resource` entries for `ThemePreview.gd` and `theme_config.tres` if no longer referenced.
- [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn):
  - Remove the `ThemePreview` node block and its `ext_resource` references.
- Placeholder scenes that include ThemePreview today:
  - [Settings.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/Settings.tscn)
  - [NewGame.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/NewGame.tscn)
  - [LoadGame.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/LoadGame.tscn)

Notes:
- This removes editor preview support from scenes, but does not require deleting the script/resource files (aligned with “disable only”).

### 3) Leave light resources in place (disable-only)

Do not delete:
- [palette_light.tres](file:///c:/Users/evans/Documents/text-based-life-sim/resources/theme/palette_light.tres)
- Light styleboxes/textures (if present)

The runtime path will not reach them once DarkMode is forced to dark-only.

## Verification Steps

- Diagnostics:
  - Ensure the project has no new errors/warnings (this repo treats warnings as errors in some cases).
- Runtime behavior:
  - Launch to MainMenu; verify UI is dark immediately without pressing any hotkey.
  - Confirm Ctrl+D no longer changes theme.
  - Navigate to Settings/NewGame/LoadGame (or open them) and confirm they are also dark.
- Regression checks:
  - Confirm SceneTransitions/UIAnimator overlays are still excluded (no “black curtain” issue returns).
