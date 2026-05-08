# Dark Mode Hotkey Toggle (Plan)

## Summary
Add a global Dark Mode toggle (Ctrl+D) that switches the UI across **all scenes** (MainMenu, placeholders, MainUI) to the provided dark palette. This is hotkey-only for now (no persistence across restarts).

## Current State Analysis (Repo Truth)
- UI is currently “light mode” with many hardcoded colors in scenes:
  - Main menu background: [MainMenu.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainMenu.tscn#L109-L116) uses a full-screen `ColorRect` set to a light gray.
  - MainUI background: [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn#L143-L151) uses a full-screen `ColorRect` set to the same light gray.
  - Shared panel style: [panel1.tres](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/ui/panels/panel1.tres) is a light `StyleBoxFlat` (used by multiple PanelContainers).
- There are already autoloads in [project.godot](file:///c:/Users/evans/Documents/text-based-life-sim/project.godot#L18-L23):
  - `GlobalShortcuts` (F11 fullscreen)
  - `SceneTransitions` (scene transition overlay)
  - `UIAnimator` (tactile button scaling)
- There is no theme system or centralized palette abstraction yet; most styling is per-node theme overrides/subresources.

## Decisions (From You)
- Toggle hotkey: **Ctrl+D**
- Scope: **All scenes**
- Palette strictness: **Exact palette**
- Persistence: **No** (resets to light on restart)

## Target Dark Palette (Exact)
- Main background: `#0B1117`
- Panel background: `#111820`
- Card background: `#151E27`
- Border: `#2A3542`
- Primary text: `#E5EAF0`
- Secondary text: `#9AA7B5`
- Accent blue: `#3B82F6`
- Soft selected bg: `#102A52`
- Money green: `#35C46A`
- Warning orange: `#F59E0B`
- Danger red: `#EF4444`

## Proposed Changes

### 1) Add a global DarkMode manager (autoload)
**New file:** `scripts/DarkMode.gd`

**Responsibilities:**
- Track a boolean `enabled` (default `false`).
- Listen for Ctrl+D via `_unhandled_key_input` and toggle `enabled`.
- Apply the palette to the **current scene and all UI nodes** (and revert cleanly back to the previous light look when disabled).
- Handle new scenes/nodes automatically (scene transitions, change_scene calls) by reapplying if `enabled` is true.

**Approach (keeps existing UI intact; no mass scene rewrites):**
- Connect to `get_tree().node_added`:
  - When `enabled` is true, immediately apply dark styling to any newly-added nodes.
- Maintain an in-memory “original values” cache per node instance so toggling off restores what was there before (avoids permanently overwriting the user’s existing UI tweaks).
  - Key by `instance_id`.
  - Store only the properties we change (ColorRect color, Control theme overrides we touch, Label overrides).
  - Clean up cache entries on `tree_exited`.

**What gets recolored (exact palette mapping):**
- **Backgrounds**
  - Full-screen `ColorRect` backgrounds (e.g., `Background` in MainMenu, root ColorRect in MainUI): set to **Main background**.
- **Panels / Cards**
  - For `PanelContainer` and other Controls using a `StyleBoxFlat` override:
    - Force `bg_color` to **Card background** (`#151E27`).
    - Force border width to `2` and `border_color` to **Border** (`#2A3542`).
    - Keep corner radius as-is (or set to `14` if missing).
  - For “large container panels” (sidebar shells / main columns) where feasible, apply **Panel background** (`#111820`).
    - Implementation chooses these by heuristic: large `PanelContainer` direct children of the scene’s primary layout containers.
- **Text**
  - Labels/buttons with dark text in light mode switch to:
    - Primary text (`#E5EAF0`) for primary labels
    - Secondary text (`#9AA7B5`) for helper/secondary labels
  - Preserve semantic colors:
    - Accent blue → `#3B82F6`
    - Money green → `#35C46A`
    - Warning orange → `#F59E0B`
    - Danger red → `#EF4444`
  - Mapping is based on existing light-mode colors already used in the project:
    - light primary text `Color(0.0666, 0.0941, 0.1529, 1)` → primary text
    - light secondary `Color(0.2941, 0.3333, 0.3882, 1)` → secondary text
    - light accent `Color(0.1451, 0.3882, 0.9216, 1)` → accent blue
    - light money `Color(0.1882, 0.6392, 0.3843, 1)` → money green
- **Selections / Active rows**
  - Active/selected backgrounds (sidebar active row, selected action card) become **Soft selected bg** (`#102A52`) with border/accent using **Accent blue** (`#3B82F6`).

### 2) Register DarkMode as an autoload
**File to update:** `project.godot`

Add under `[autoload]`:
- `DarkMode="*res://scripts/DarkMode.gd"`

### 3) No scene file rewrites in this phase
To keep this hotkey-only feature low-risk, dark mode is applied at runtime via the autoload rather than editing 200+ hardcoded color lines across scenes.

If later you want “real” theme switching (clean resource-based light/dark themes), we can refactor the UI to rely on a shared Theme and reduce per-node overrides.

## Assumptions & Constraints
- Dark mode must not permanently overwrite existing light UI tweaks; toggling off restores prior values.
- Works with current autoload setup (GlobalShortcuts, SceneTransitions, UIAnimator).
- No persistence in user config yet (per decision).

## Verification
- Launch project (MainMenu).
- Press Ctrl+D:
  - MainMenu backgrounds/panels/text switch to the provided palette.
  - Buttons remain readable (primary/secondary text and borders update).
- Navigate: New Game / Load Game / Settings / Back / Continue:
  - Dark mode remains active across scene transitions.
  - No console errors.
- Press Ctrl+D again:
  - UI returns to the prior light look (not a “new” light theme).
