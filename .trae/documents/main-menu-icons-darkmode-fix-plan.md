# Fix Main Menu SVG Icons in Dark Mode (Plan)

## Summary
Fix Main Menu SVG icons disappearing in dark mode (both editor preview and runtime Ctrl+D) by:
- Ensuring the icon “tile” Panels actually switch to dark colors in editor preview (ThemePreview currently doesn’t recolor `Panel`)
- Making Main Menu icon `TextureRect`s tintable and correctly tinted (so they stay visible in both light and dark palettes)

## Current State Analysis (Repo Truth)
- Main Menu icons are `TextureRect`s, many tagged `groups=["theme_no_icon_tint"]`:
  - Example: Brand icon texture at `TopBar/Brand/BrandIcon/Icon` in [MainMenu.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainMenu.tscn#L652-L666)
  - Action icons inside `IconTile` panels: [MainMenu.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainMenu.tscn#L1184-L1199)
- The icon tile backgrounds (`BrandIcon`, `IconTile`) are `Panel` nodes, not `PanelContainer`:
  - Example: `BrandIcon` is `type="Panel"` with a light stylebox: [MainMenu.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainMenu.tscn#L652-L656)
- SVG sources are monochrome white (stroke `#FFFFFF`), e.g. [file-plus.svg](file:///c:/Users/evans/Documents/text-based-life-sim/assets/icons/file-plus.svg#L1-L6).
  - This means visibility depends heavily on the background/tint pipeline (white-on-light disappears).
- Editor dark preview is driven by `ThemePreview.gd`:
  - It recolors `PanelContainer` but does **not** recolor `Panel`, so icon tiles can remain light in preview.
- Runtime dark mode is driven by `DarkMode.gd`, and the user wants the fix specifically around [DarkMode.gd:L226-L678](file:///c:/Users/evans/Documents/text-based-life-sim/scripts/DarkMode.gd#L226-L678).

## Decisions (From You)
- Missing icons: **Both editor preview and runtime Ctrl+D**
- Icon color in dark mode: **Primary text**
- Icon tiles/pills should follow dark mode: **Yes**

## Proposed Changes

### 1) Make editor preview recolor `Panel` nodes (icon tiles)
**File:** `scripts/theme/ThemePreview.gd`

Add support for `Panel` (in addition to `PanelContainer`):
- In `_apply_node`, handle `if node is Panel: _apply_panel(node as Panel, palette)`
- Implement `_apply_panel(panel: Panel, palette)` mirroring the PanelContainer logic:
  - Duplicate the `panel` stylebox if it’s `StyleBoxFlat`
  - Set `bg_color` to `palette.card_bg` (or `palette.panel_bg` using the same sizing heuristic)
  - Set `border_color` to `palette.border`

This ensures the light icon tiles become dark in preview, so white SVGs are visible.

### 2) Ensure Main Menu icon TextureRects are tintable and visible by default
**File:** `scenes/main/MainMenu.tscn`

For the Main Menu’s icon `TextureRect`s that are currently `theme_no_icon_tint`:
- Remove `groups=["theme_no_icon_tint"]` from these icon TextureRects:
  - Brand icon
  - Hero app icon
  - Avatar icon
  - Action icons inside each `IconTile` (New Game / Load Game / Settings / Quit)
- Set an explicit `modulate` in the scene to match **light palette primary text** (so they are visible even before any runtime toggle runs).

Rationale:
- Since SVGs are white, the base texture is tint-friendly via multiplication.
- Removing the “no tint” group allows both ThemePreview and DarkMode to tint icons to the current palette in dark mode.
- Explicit light-mode `modulate` prevents “invisible icons until you toggle dark mode twice” behavior.

### 3) Make runtime Ctrl+D reliably recolor the same icon tiles and icons
**File:** `scripts/DarkMode.gd` (focus on the reported range)

Confirm/adjust `DarkMode.gd` so:
- `Panel` nodes are recolored (icon tiles) using the palette-based values.
- `TextureRect` icons are tinted to `palette.text_primary` unless explicitly excluded.

If any remaining logic still prevents MainMenu icon tiles/icons from updating (e.g., early returns on `theme_no_icon_tint`), align it with step (2) so MainMenu icons update correctly.

## Assumptions & Constraints
- Keep layout unchanged; only touch icon visibility (groups/modulate + preview recolor).
- Keep the palette source of truth as `resources/theme/theme_config.tres`.

## Verification
- Editor:
  - Open `MainMenu.tscn`, toggle `ThemePreview.preview_dark`: icon tiles go dark and icons remain visible.
  - Tweak `palette_dark.tres` and confirm preview updates still show icons.
- Runtime:
  - Run from Main Menu, press Ctrl+D: icons remain visible and icon tiles switch to dark palette.
  - Toggle back to light: icons remain visible (no “disappear until second toggle”).
