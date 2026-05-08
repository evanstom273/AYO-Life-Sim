# Inspector Theme Controls + Editor Light/Dark Preview (Plan)

## Summary
Add an inspector-editable theme palette system (light + dark) backed by shared `.tres` resources, plus an in-editor preview toggle to switch between light/dark without running the game. Runtime Ctrl+D dark mode will use the same palettes.

## Current State Analysis (Repo Truth)
- Runtime dark mode exists as an autoload: `DarkMode="*res://scripts/DarkMode.gd"` in [project.godot](file:///c:/Users/evans/Documents/text-based-life-sim/project.godot#L18-L24).
- The current DarkMode implementation is hardcoded (constants inside `scripts/DarkMode.gd`) and applies colors by heuristics (node types + mapping from known light colors).
- There is no centralized palette resource; many colors are embedded in scenes (e.g. `ColorRect` backgrounds, `StyleBoxFlat` subresources, `theme_override_colors/*`).
- There is existing `@tool` usage in the repo (e.g. [UpdateSVG.gd](file:///c:/Users/evans/Documents/text-based-life-sim/scripts/UpdateSVG.gd)), so editor-time scripts are acceptable.

## Decisions (From You)
- Location: **Shared palette resource** (single source of truth, not per-scene manual).
- Runtime: **Ctrl+D uses the same palettes**.
- Inspector scope: **Palette only** (expose core colors; derive states like hover/selected from those).
- Editor workflow: **Tool preview toggle** (live preview in the editor).

## Palette Fields (Inspector-Editable)
Expose these colors in a palette resource:
- Main background
- Panel background
- Card background
- Border
- Primary text
- Secondary text
- Accent blue
- Soft selected bg
- Money green
- Warning orange
- Danger red

## Proposed Changes

### 1) Introduce theme Resource types
**New files:**
- `scripts/theme/ThemePalette.gd` (`class_name ThemePalette`, `extends Resource`)
  - `@export var main_bg: Color`
  - `@export var panel_bg: Color`
  - `@export var card_bg: Color`
  - `@export var border: Color`
  - `@export var text_primary: Color`
  - `@export var text_secondary: Color`
  - `@export var accent_blue: Color`
  - `@export var selected_bg: Color`
  - `@export var money_green: Color`
  - `@export var warning_orange: Color`
  - `@export var danger_red: Color`

- `scripts/theme/ThemeConfig.gd` (`class_name ThemeConfig`, `extends Resource`)
  - `@export var light: ThemePalette`
  - `@export var dark: ThemePalette`

### 2) Add shared palette resources you can edit
**New files:**
- `resources/theme/palette_light.tres`
  - Values matching the project’s current “light” defaults (background/panel/border/text/accent).
- `resources/theme/palette_dark.tres`
  - Values matching your provided dark palette.
- `resources/theme/theme_config.tres`
  - References `palette_light.tres` and `palette_dark.tres`.

These are the primary “inspector controls”: open `theme_config.tres` and/or the palette `.tres` files and tweak colors.

### 3) Refactor DarkMode autoload to use ThemeConfig resource
**File to update:** `scripts/DarkMode.gd`

**Change:**
- Remove hardcoded palette constants (or keep as fallback defaults only).
- Load `ThemeConfig` from a fixed path (e.g. `res://resources/theme/theme_config.tres`).
- When toggling enabled/disabled:
  - Apply either `config.dark` or `config.light`.

**Apply strategy (keep behavior stable, but palette-driven):**
- Continue using the current “apply to node types + cache original overrides” model.
- Replace all “DARK_*” assignments with palette values from the loaded resource.
- Replace mapping rules to use palette values:
  - Fullscreen `ColorRect` → `palette.main_bg` (preserve alpha)
  - PanelContainer StyleBoxFlat bg/border → `palette.card_bg` or `palette.panel_bg` + `palette.border`
  - Text/icon colors previously mapped from known light values → directly set to `palette.text_primary`, `palette.text_secondary`, `palette.accent_blue`, etc.
  - Selected backgrounds → `palette.selected_bg` + `palette.accent_blue` border

**Notes:**
- Keep the existing “exclude autoload UI” safeguards so DarkMode doesn’t recolor transition overlays.
- Keep the existing per-node cache so toggling back restores prior values cleanly.

### 4) Add an editor preview toggle node (tool script)
**New file:** `scripts/theme/ThemePreview.gd` (`@tool`, `extends Node`)

**Inspector fields:**
- `@export var config: ThemeConfig` (default to `res://resources/theme/theme_config.tres`)
- `@export var preview_dark: bool = false`

**Behavior:**
- When `preview_dark` changes in the inspector (setter), apply palette to the currently edited scene root:
  - If `preview_dark` true → apply `config.dark`
  - Else → apply `config.light`
- Uses the same application logic as runtime (shared helper functions inside ThemePreview or delegated to DarkMode-style functions), but:
  - Never touches `/root/SceneTransitions` or other autoloads in the editor.
  - Applies only to `get_tree().edited_scene_root` (so the preview doesn’t bleed into other editor UI).

### 5) Add the preview node into scenes for easy access
**Files to update:**
- `scenes/main/MainUI.tscn`
- `scenes/main/MainMenu.tscn`
- `scenes/main/NewGame.tscn`
- `scenes/main/LoadGame.tscn`
- `scenes/main/Settings.tscn`

Add a child node (e.g. `ThemePreview`) with `ThemePreview.gd` attached and `config` set to `theme_config.tres`.
This gives you a per-scene inspector toggle to preview Light/Dark instantly.

## Assumptions & Constraints
- The goal is palette control + preview, not a full Godot Theme refactor (no global `.theme` asset yet).
- Palette controls are intentionally limited to the 11 core colors; hover/pressed colors remain derived.
- Avoid reverting your existing UI tweaks; palette application remains reversible via cached originals.

## Verification
- Editor:
  - Open `MainUI.tscn`, select `ThemePreview`, toggle `preview_dark` on/off and observe immediate palette changes.
  - Edit colors inside `palette_dark.tres` and see the scene update after toggling (or on re-apply).
- Runtime:
  - Press Ctrl+D and confirm DarkMode switches using the palettes from `theme_config.tres`.
  - Confirm no overlay “black curtain” regressions and no console errors.
