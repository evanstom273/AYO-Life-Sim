## Summary
- Make **all on-screen text** (Labels, Buttons, etc.) crisp and easier to read while **changing nothing unrelated to text**.
- Root cause in current setup: the project renders a 1920×1080 viewport and scales it down to a 1280×720 window using `window/stretch/mode="viewport"`, which produces fractional scaling and blurry text.
- Fix by switching to a UI-friendly stretch mode and setting project-wide GUI font settings using a single bundled font file.

## Current State Analysis (Repo-Grounded)
- Project uses Godot 4.6 (from [project.godot](file:///c:/Users/evans/Documents/text-based-life-sim/project.godot)).
- Display config (blurry risk):
  - `window/size/viewport_width=1920`, `viewport_height=1080`
  - `window/size/window_width_override=1280`, `window_height_override=720`
  - `window/stretch/mode="viewport"`, `window/stretch/aspect="expand"`
  - This scales the entire rendered viewport by ~0.666… at startup, which can blur all UI text.
- UI scene currently present: [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn).
- `assets/fonts/` exists but is empty: [assets/fonts](file:///c:/Users/evans/Documents/text-based-life-sim/assets/fonts).

## Decisions (From You)
- Approach: **Both** (switch to a crisp stretch mode + standardize project-wide font settings).
- Fonts: **Add font file** (TTF/OTF) and use it as default GUI font.
- Scope: **Project-wide** (Project Settings GUI theme defaults).
- Success criterion: **Crispness first**, even if scaling behavior changes slightly.

## Proposed Changes
### 1) Switch away from viewport scaling (primary blur fix)
File: [project.godot](file:///c:/Users/evans/Documents/text-based-life-sim/project.godot)
- Change:
  - `window/stretch/mode` from `"viewport"` → `"canvas_items"`
  - Keep `window/stretch/aspect="expand"` unless testing shows undesirable behavior.
- Align base viewport size to the startup window size to avoid any implicit scaling at launch:
  - Set `window/size/viewport_width=1280`
  - Set `window/size/viewport_height=720`
  - Keep `window/size/window_width_override=1280`, `window_height_override=720`

Why:
- `viewport` mode intentionally scales the entire output; it commonly causes blurred UI text when the scale factor isn’t an integer.
- `canvas_items` avoids rendering UI as a downscaled texture and tends to keep Control text crisp.

### 2) Add a single project font file
File(s):
- `assets/fonts/<chosen_font>.ttf` (one new font file)

Source choice (implementation detail):
- Prefer a clear UI font with good hinting (e.g., Inter or similar).
- Implementation will download the font into `assets/fonts/` using a non-interactive PowerShell web request (or you can drop a TTF/OTF into the folder manually).

### 3) Set project-wide GUI font + rendering knobs (text-only)
File: [project.godot](file:///c:/Users/evans/Documents/text-based-life-sim/project.godot)
- Set default GUI font to the added font file via Project Settings keys under `gui/theme/*`:
  - `gui/theme/default_font = "res://assets/fonts/<chosen_font>.ttf"`
  - `gui/theme/default_font_size = 16` (or 18 if you want slightly larger across the board; default to 16 to minimize layout impact)
  - `gui/theme/default_font_antialiasing = 1` (grayscale)
  - `gui/theme/default_font_hinting = 1` (auto/standard hinting)
  - `gui/theme/default_font_subpixel_positioning = 0` (disable subpixel positioning for sharper edges)
  - Keep MSDF off unless needed:
    - `gui/theme/default_font_multichannel_signed_distance_field = false`
  - Keep mipmaps off initially:
    - `gui/theme/default_font_generate_mipmaps = false`

Why:
- A consistent dynamic font + sane hinting/subpixel settings improves legibility.
- Disabling subpixel positioning often makes text appear sharper (at the cost of slightly less smooth positioning), which matches “crispness first”.

### 4) No scene/layout changes
- Do not touch node structure/layout for MainUI (or any other scene) as part of this task.
- Any existing per-node font size overrides remain (they won’t cause blur once viewport scaling is removed).

## Assumptions & Constraints
- “Changing NOTHING else” means:
  - Only project-wide text rendering configuration (GUI theme defaults) and the display stretch mode change needed to eliminate blur.
  - No gameplay logic, node layout restructuring, or non-text styling changes.
- Adding one font file is acceptable (you explicitly approved this).

## Verification Steps
- Open project, run MainUI at the default window size (1280×720):
  - Buttons and labels render with noticeably sharper text (no “downscaled texture” look).
- Resize the window:
  - Text remains acceptably crisp (minor differences acceptable; crispness prioritized).
- Confirm no scene hierarchy/layout edits were made beyond text-related project settings.
