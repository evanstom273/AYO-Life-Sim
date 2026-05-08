# Main Menu as Separate Scene (Plan)

## Summary
Create a new dedicated Main Menu scene that matches the provided mock (LifeSim hero card + Recent Save card + 2×2 action grid), wire all buttons to real/placeholder scenes, and set it as the project startup scene.

## Current State Analysis (Repo Truth)
- The only existing scene is [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn) (the in-game dashboard UI).
- There is currently no title/main menu UI scene in the repo and no scene configured as the startup scene in [project.godot](file:///c:/Users/evans/Documents/text-based-life-sim/project.godot).
- Shared UI styling exists via [panel1.tres](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/ui/panels/panel1.tres) and global GUI font settings in project.godot (Inter, canvas_items stretch).
- Icons live in `assets/icons/` and are currently sourced from Lucide (see `assets/icons/ICON_LICENSES.txt`).

## Decisions (From You)
- Startup: set the new Main Menu as the project main scene.
- Buttons: “All wired” (Continue/New Game/Load Game/Settings/Quit all do something).
- Recent Save: static placeholder content for now (no save I/O yet).
- Icons: add new SVG icons to better match the mock.

## Proposed Changes

### 1) Add a new main menu scene
**File:** `scenes/main/MainMenu.tscn` (new)

**Goal:** Recreate the mock layout using existing styling conventions (light background + rounded panel cards).

**Concrete palette (reuse existing values already in MainUI where possible):**
- Background: `Color(0.9529412, 0.95686275, 0.9647059, 1)` (same as MainUI background ColorRect)
- Card panel: `panel1.tres` (`bg_color = Color(0.96, 0.964, 0.972, 1)`, rounded 14, subtle border)
- Primary text: `Color(0.06666667, 0.09411765, 0.15294118, 1)` (same as MainUI inactive sidebar text)
- Muted text/icon: `Color(0.29411766, 0.33333334, 0.3882353, 1)` (same as MainUI inactive icon tint)
- Accent blue: `Color(0.14509805, 0.3882353, 0.92156863, 1)` (same as MainUI active tint)
- Accent bg (selected/highlighted): `Color(0.8666667, 0.92156863, 1, 1)` (same as MainUI active row background)

**Structure (high-level):**
- `Control` (root)
  - `ColorRect` (full-screen background, reuse the same light gray used by MainUI)
    - `MarginContainer` (outer padding similar to MainUI, e.g. 16)
      - `VBoxContainer` (main vertical flow)
        - `TopBar` (`HBoxContainer`)
          - Left: `HBoxContainer` with small icon + `Label` “LifeSim”
          - Right: icon-only buttons (… and gear) matching mock
        - `MainCardsRow` (`HBoxContainer`, separation ~16–24)
          - `HeroCard` (`PanelContainer` using `panel1.tres`)
            - Left column: app icon tile + “LifeSim” title + subtitle + short description
            - Right column: 4 feature rows (icon + bold-ish title + small description)
          - `RecentSaveCard` (`PanelContainer` using `panel1.tres`)
            - Header row: “Recent Save” + small clock icon
            - Profile row: avatar placeholder + a 2-column grid of fields (Age, Year, Occupation, Cash with green value)
            - Latest Summary: title + date + 1–2 lines of placeholder summary text
            - Primary button: “Continue”
        - `ActionsGrid` (`GridContainer`, columns=2)
          - Four “row cards” as clickable controls:
            - New Game (highlighted/active border like mock)
            - Load Game
            - Settings
            - Quit
        - `Footer` (`HBoxContainer`)
          - Left: version text (static, e.g. “v0.1.0 • Desktop Preview”)
          - Right: “Thank you for playing!” + small heart icon

**Styling approach:**
- Reuse `panel1.tres` for card panels to stay consistent with the rest of the UI.
- Implement “row cards” as `Button` nodes (so we get keyboard focus + pressed/hover states), with `flat = true` and theme overrides:
  - `theme_override_styles/normal|hover|pressed` using per-scene `StyleBoxFlat` subresources
  - Child layout inside each button: `HBoxContainer` → left icon tile (`Panel` + `TextureRect`) → `VBoxContainer` (title + subtitle labels) → spacer → chevron `TextureRect`
- Create per-scene `StyleBoxFlat` subresources for:
  - Action-row normal: transparent bg
  - Action-row hover/pressed: slightly darker light gray
  - “New Game” highlighted: accent border (2px) + very light accent bg
  - Continue button: very light accent bg + blue text (and slightly darker hover)
- Use `theme_override_colors/icon_*_color` patterns already used in MainUI for icon tinting.
- Keep layout container-driven (no manual position offsets) so it scales cleanly across window sizes.

### 2) Wire all buttons (scene switching + quit)
**Files:**
- `scripts/MainMenu.gd` (new)
- `scenes/main/MainMenu.tscn` (connect buttons to script)

**Behavior:**
- Continue → switches to `scenes/main/MainUI.tscn`
- New Game → switches to `scenes/main/NewGame.tscn` (placeholder scene)
- Load Game → switches to `scenes/main/LoadGame.tscn` (placeholder scene)
- Settings → switches to `scenes/main/Settings.tscn` (placeholder scene)
- Quit → `get_tree().quit()`

**Implementation details:**
- Use `get_tree().change_scene_to_file("res://...")` for scene transitions.
- Keep script minimal: exported `String` paths for each destination so it’s easy to change later without touching code.

### 3) Add placeholder scenes for New Game / Load Game / Settings
**Files (new):**
- `scenes/main/NewGame.tscn`
- `scenes/main/LoadGame.tscn`
- `scenes/main/Settings.tscn`
- `scripts/MenuPlaceholder.gd` (optional, shared) OR inline minimal scripts per scene

**Each placeholder scene contains:**
- Title label (e.g. “New Game (Placeholder)”)
- A “Back” button that returns to `MainMenu.tscn`

This satisfies “All wired” while keeping scope tight (no actual gameplay/save/settings systems).

### 4) Add missing icons used by the menu mock
**Files (new):** add SVGs under `assets/icons/`

**Planned icon set (Lucide-based, consistent with existing attribution):**
- `sparkles.svg` (hero/app tile)
- `user.svg` or `circle-user.svg` (avatar placeholder)
- `plus.svg` or `file-plus.svg` (New Game)
- `folder-open.svg` (Load Game)
- `settings.svg` (Settings)
- `power.svg` (Quit)
- `chevron-right.svg` (row affordance)
- `ellipsis.svg` (top bar “…”)

**Note on Godot imports:**
- The repo currently tracks `.svg.import` files for icons. Godot will generate these automatically when the project is opened. After implementation, open the project once in the editor and add the generated `.import` metadata files if you want them checked in for cleanliness.

### 5) Set the startup scene
**File:** [project.godot](file:///c:/Users/evans/Documents/text-based-life-sim/project.godot)

**Change:**
- Add `run/main_scene="res://scenes/main/MainMenu.tscn"` under `[application]`.

## Assumptions & Constraints
- This work is UI-first: no save format exists yet, so “Recent Save” stays placeholder text.
- Maintain existing UI conventions; do not modify or revert prior UI tweaks in MainUI unless required for navigation only.
- No changes to promotion names in `.tres` (not involved here).

## Verification
- Open the project and confirm it starts on the Main Menu.
- Click each action card/button:
  - Continue loads MainUI.
  - New Game / Load Game / Settings open their placeholder scenes.
  - Back returns to Main Menu from each placeholder scene.
  - Quit exits the app.
- Resize the window (e.g., 1280×720 up to 1920×1080) and confirm layout remains clean without overlaps/clipping.
