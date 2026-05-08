## Summary
- Apply the requested UI polish to the existing Godot scene while keeping the hierarchy clean and reusing the current structure as much as possible.
- Scope:
  - Left sidebar: rename “Home” → “Overview”, unify row sizing/spacing, and apply the specified active/inactive styles (including icon tint).
  - Center panel: add a proper “Life Log” header row with a right-aligned “Filters” button, and add a ScrollContainer + entries VBox for future content plus bottom space for a primary button later.
  - Life Goals card: swap bullet Labels for CheckBox controls (4 goals), keep progress label + bar.
  - Global look: set main background to light gray and panels to a slightly lighter gray with subtle border, rounded corners, and consistent inner padding.

## Current State Analysis (Repo-Grounded)
- Main scene: [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn)
  - Background is a `ColorRect` with semi-transparent white ([MainUI.tscn:L57-L65](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn#L57-L65)).
  - Left sidebar is `HBoxContainer/PanelContainer` with a `VBoxContainer` of `Button` nodes (currently “Home” active) and a `LifeGoalsCard` below ([MainUI.tscn:L181-L406](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn#L181-L406)).
  - Center panel is `HBoxContainer/MarginContainer/PanelContainer` and is currently empty (no header/scroll structure) ([MainUI.tscn:L411-L421](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn#L411-L421)).
  - Right panel exists as `PanelContainer2` and is currently empty ([MainUI.tscn:L427-L430](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn#L427-L430)).
- Shared panel style is a `StyleBoxFlat` resource: [panel1.tres](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/ui/panels/panel1.tres)
  - Currently uses heavy 4px borders and darker gray background ([panel1.tres:L4-L13](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/ui/panels/panel1.tres#L4-L13)).
- Sidebar row styles currently use in-scene `StyleBoxFlat_*` subresources (active/hover/normal) with 12px corner radius ([MainUI.tscn:L14-L47](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn#L14-L47)).

## Decisions (From You)
- Active sidebar row: **Overview** (rename the first item and keep it selected).
- Life Goals: **Buy a house** is checked to match “1 / 4 goals completed”.
- Panel background style: **Gray panels** (background light gray; panels slightly lighter gray with subtle border).

## Proposed Changes (Decision-Complete)
### A) Global light dashboard style (background + panels)
Files:
- [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn)
- [panel1.tres](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/ui/panels/panel1.tres)

Changes:
- Set the main background `ColorRect.color` to an opaque light gray (no translucency) to match a desktop dashboard feel.
  - Target color: #F3F4F6 (or closest RGB in `Color(r,g,b,a)`).
- Update [panel1.tres](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/ui/panels/panel1.tres) to a softer, modern panel style:
  - `bg_color`: slightly lighter gray than background (e.g., #F8FAFC-ish).
  - `border_width_*`: 1 (soft border).
  - `border_color`: soft gray (e.g., #E5E7EB-ish).
  - `corner_radius_*`: 12–14 (keep 14 unless it clashes with 8px sidebar rows).
  - Enable `anti_aliasing = true` for smoother rounded edges (with small size).
Why:
- This gives a consistent “panel” look across left/center/right containers without introducing new theme files.

### B) Left sidebar: rename + row layout + active/inactive styling (including icon tint)
File: [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn)

1) Rename the first sidebar item
- Update the first sidebar button’s displayed text from “Home” to “Overview” ([MainUI.tscn:L201-L215](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn#L201-L215)).
- Keep the node name as-is unless it’s safe to rename; default plan: **change text only** to avoid breaking any future references.

2) Navigation row sizing/spacing
- Set sidebar `VBoxContainer.theme_override_constants/separation = 12` ([MainUI.tscn:L197-L200](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn#L197-L200)).
- Set each sidebar button `custom_minimum_size.y` to ~48 (currently 44) for consistent row height (applies to all nav buttons).

3) Icon sizing (20–24px)
- Add `theme_override_constants/icon_max_width = 24` on sidebar buttons.
- Keep `expand_icon = false` so icons don’t scale to full button height.

4) Active/inactive/hover visuals using StyleBoxFlat + theme override colors
- Update the existing StyleBox subresources (or replace them with new ones) to match requested tokens:
  - **Active row**:
    - Background: #DDEBFF
    - Text color: #2563EB
    - Icon color: #2563EB (use `theme_override_colors/icon_*_color`)
    - Rounded corners: 8
    - Optional left accent border: set `border_width_left = 3` and `border_color = #2563EB`
  - **Inactive row**:
    - Background: transparent (or extremely subtle)
    - Text color: #111827
    - Icon color: #4B5563
    - Rounded corners: 8
  - **Hover**:
    - Very subtle fill (e.g., #F3F4F6) while keeping inactive text/icon colors.
- Apply per-button theme overrides:
  - `theme_override_colors/font_color`, `font_hover_color`, `font_pressed_color`
  - `theme_override_colors/icon_normal_color`, `icon_hover_color`, `icon_pressed_color`
Why:
- This achieves distinct icon vs text colors without adding extra child nodes inside each button.

### C) Center “Life Log” panel: header + scroll-ready structure + bottom space
File: [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn)

Scope: `ColorRect/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/PanelContainer` ([MainUI.tscn:L411-L421](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn#L411-L421))

Add the following children inside the center `PanelContainer`:
1) `MarginContainer` (panel inner padding)
  - margins: 12–16 (default to 16 to match the mockup spacing).
2) `VBoxContainer` (vertical layout root)
  - separation: 12.
3) Header row (`HBoxContainer`)
  - Left: `Label` text “Life Log”
    - font size: 18–20 (default 20 for “bold-looking” via size; keep weight default to avoid extra font resources)
  - Middle: `Control` spacer with `size_flags_horizontal = EXPAND_FILL`
  - Right: `Button` text “Filters”
    - Styled with a light StyleBoxFlat (radius 8, subtle border) via theme overrides.
4) Content area
  - `ScrollContainer` (expand to fill)
    - child `VBoxContainer` named `LifeLogEntries` for future entries
    - Keep it mostly empty (optionally a single subtle placeholder Label like “No entries yet” can be skipped to keep it clean).
5) Bottom reserved space
  - Add a `Control` with `custom_minimum_size.y` ~64–80 to reserve space for a future primary “AGE 1 YEAR” button.

### D) Life Goals card: CheckBox goals + progress retained
File: [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn)

Scope: `LifeGoalsCard` under the left sidebar ([MainUI.tscn:L349-L406](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn#L349-L406))

Changes:
- Replace the current bullet `Label` nodes `Goal1/Goal2/Goal3` with `CheckBox` nodes:
  - “Buy a house” (checked = true)
  - “Visit 10 countries”
  - “Start a family”
  - “Retire comfortably”
- Keep:
  - `ProgressLabel` text “1 / 4 goals completed”
  - `ProgressBar` with `max_value=4` and `value=1` (25%)
- Keep spacing and text readable:
  - Use small font size (12–14) and container separation 6–8.

## Assumptions & Constraints
- No gameplay/data binding is added; this is UI structure + styling only.
- “Existing node structure as much as possible”:
  - Sidebar stays as Buttons (no per-row custom sub-hierarchies).
  - Center panel adds only the containers required to support header + scroll content cleanly.
- No new art/illustrations/portraits are introduced.

## Verification Steps
- Open [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn) and confirm:
  - Left sidebar first item reads “Overview”.
  - All sidebar rows are ~48px tall, with ~12px spacing, icons remain ~20–24px.
  - Active row matches: bg #DDEBFF, text/icon #2563EB, radius 8, optional left accent.
  - Inactive rows match: transparent/subtle bg, text #111827, icon #4B5563, radius 8.
  - Center panel shows “Life Log” header and right-aligned “Filters” button; scroll structure exists with entries VBox; bottom reserved space exists.
  - Life Goals uses CheckBoxes (4) with “Buy a house” checked; progress still shows 1/4 and 25%.
  - Background/panels match the light gray dashboard direction with subtle borders.
