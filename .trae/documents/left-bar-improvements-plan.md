## Summary
- Improve the look and layout of the **left sidebar only** in [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn).
- Target: a cleaner “rounded cards” aesthetic, narrower width (~240px), a single statically-highlighted active item, and a “Life Goals” card at the bottom.
- No changes outside the left sidebar branch of the scene.

## Current State Analysis
- Left sidebar is the `PanelContainer` at `ColorRect/MarginContainer/VBoxContainer/HBoxContainer/PanelContainer` in [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn#L172-L326).
- It is currently:
  - Fixed width: `custom_minimum_size = Vector2(350, 0)` ([MainUI.tscn:L176-L179](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn#L176-L179)).
  - A vertical list of Buttons (“Home”, “Relationships”, …) each styled as a bordered rounded card, using:
    - Normal: `ExtResource("1_c6qpx")` → [panel1.tres](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/ui/panels/panel1.tres)
    - Pressed/Hover: local StyleBoxFlat subresources ([MainUI.tscn:L14-L40](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn#L14-L40)).
  - A bottom placeholder: `Panel` with `custom_minimum_size = Vector2(0, 250)` ([MainUI.tscn:L322-L325](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn#L322-L325)).
- Sidebar icons are SVG textures already present under `assets/icons/` and referenced as ext resources ([MainUI.tscn:L4-L12](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn#L4-L12)).

## Decisions (From You)
- Visual direction: Rounded cards (cleaner, less heavy borders).
- Width: ~240px.
- Active section: Static highlight (no selection logic changes).
- Bottom area: Replace placeholder with a “Life Goals” card (still confined to left bar).

## Proposed Changes (Left Bar Only)
File: [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn)

### 1) Sidebar container sizing + padding
Scope: `ColorRect/MarginContainer/VBoxContainer/HBoxContainer/PanelContainer` and its immediate child `MarginContainer`.
- Change sidebar width from 350 to ~240:
  - `PanelContainer.custom_minimum_size = Vector2(240, 0)`
- Increase inner padding slightly for a cleaner layout:
  - `PanelContainer/MarginContainer.theme_override_constants/margin_*` from 8 → 12–16 (pick consistent value; default to 12).
- Tighten list spacing:
  - Sidebar `VBoxContainer.theme_override_constants/separation` from 10 → 6–8 (default to 8).

### 2) Introduce dedicated left-bar StyleBoxes (avoid changing global panel1.tres)
Reason: [panel1.tres](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/ui/panels/panel1.tres) is used elsewhere; editing it would likely change non-left-bar UI.
- Add new `StyleBoxFlat` subresources in [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn) for left-bar-only styling:
  - **SidebarBackground**: subtle bg color, very light border, rounded corners.
  - **NavItemNormal**: transparent/near-transparent background, rounded corners, generous content margins.
  - **NavItemHover**: light gray background.
  - **NavItemActive**: light accent background + a left border accent (using `border_width_left` and `border_color`), rounded corners.
- Apply **SidebarBackground** only to the left sidebar `PanelContainer.theme_override_styles/panel`.

### 3) Restyle nav buttons as “list items” (rounded, lighter, consistent height)
Scope: Buttons under `.../PanelContainer/MarginContainer/VBoxContainer`:
`Home`, `Relationships`, `Career`, `Education`, `Health`, `Finances`, `Assets`, `Activities`, `History` ([MainUI.tscn:L192-L316](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn#L192-L316)).
- For all nav buttons:
  - Set consistent height: `custom_minimum_size = Vector2(0, 44)` (or 40 if you prefer tighter).
  - Keep left alignment: `alignment = 0`.
  - Ensure readable spacing between icon and text via theme constants:
    - `theme_override_constants/h_separation = 10–12`
    - Add/adjust StyleBox content margins (preferred) so text aligns well.
  - Replace per-button `theme_override_styles/*` to use the left-bar subresources:
    - normal → NavItemNormal
    - hover → NavItemHover
    - pressed → NavItemHover (since selection is static; pressed is brief)
- Static active highlight:
  - Apply NavItemActive only to the chosen active button (default: `Home`), by setting that button’s `theme_override_styles/normal = NavItemActive` while keeping hover/pressed consistent.
  - Keep text/icon colors consistent (dark text on light bg); adjust `theme_override_colors/font_*` only if necessary.

### 4) Convert bottom placeholder into a “Life Goals” card (left bar only)
Scope: Replace the existing `Panel` node at [MainUI.tscn:L322-L325](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn#L322-L325).
- Replace `Panel` with a small card structure:
  - `PanelContainer` (uses SidebarBackground or a slightly different Card stylebox subresource)
    - `MarginContainer` (padding 12)
      - `VBoxContainer` (separation 6–8)
        - Header row (`HBoxContainer`):
          - `Label` “Life Goals”
        - A few goal rows as placeholder `HBoxContainer`s with a small indicator and text, or simple `Label`s.
        - A `ProgressBar` (optional) to mimic the screenshot’s “goals completed” feel.
- Keep it compact:
  - `custom_minimum_size = Vector2(0, 180–220)` rather than 250, to reduce heaviness.
- Do not touch any non-left-bar content; this card stays under the sidebar’s `VBoxContainer`.

### 5) Optional robustness (still left bar only)
- If the window height is small, the nav list + goals card may overflow.
  - Option A (minimal): keep as-is and accept clipping.
  - Option B (better): wrap the nav buttons (not the goals card) inside a `ScrollContainer` so only the list scrolls.
  - Default for execution: Option A unless overflow is observed when testing.

## Assumptions & Constraints
- Only nodes under `ColorRect/MarginContainer/VBoxContainer/HBoxContainer/PanelContainer` will be edited/added/removed.
- No new image assets are required; existing SVG icons remain.
- No scripts are introduced/edited as part of this left-bar visual polish.

## Verification Steps
- Open [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn) in Godot and confirm:
  - Sidebar width is ~240px and padding feels consistent.
  - Buttons look like clean rounded list items with hover feedback.
  - “Home” (or the chosen item) has a static active highlight.
  - Bottom section displays as a “Life Goals” card and stays within the left bar.
  - No visual/layout changes occur outside the left sidebar.
