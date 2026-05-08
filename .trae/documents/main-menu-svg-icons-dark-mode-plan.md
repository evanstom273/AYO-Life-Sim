## Summary

Fix MainMenu SVG icon visibility in dark mode by making the affected `TextureRect` icons tintable (remove `theme_no_icon_tint`) and giving them a correct light-mode baseline tint (dark text color) so they render on the very light icon-tile background.

## Current State Analysis

- MainMenu uses small “icon tiles” implemented as `Panel` nodes with `theme_override_styles/panel = StyleBoxFlat_icon_tile`, whose `bg_color` is near-white ([MainMenu.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainMenu.tscn#L19-L30)).
- Several SVG assets are authored with white strokes (e.g. [users.svg](file:///c:/Users/evans/Documents/text-based-life-sim/assets/icons/users.svg#L1-L1), [sparkles.svg](file:///c:/Users/evans/Documents/text-based-life-sim/assets/icons/sparkles.svg#L1-L4)), so they rely on `TextureRect.modulate` to be visible on light backgrounds.
- Runtime dark mode tints `TextureRect` icons unless the node is in group `theme_no_icon_tint` ([DarkMode.gd](file:///c:/Users/evans/Documents/text-based-life-sim/scripts/DarkMode.gd#L486-L503)).
- Editor preview tints `TextureRect` icons unless the node is in group `theme_no_icon_tint` ([ThemePreview.gd](file:///c:/Users/evans/Documents/text-based-life-sim/scripts/theme/ThemePreview.gd#L419-L425)).
- In MainMenu, the icons that are currently marked `groups=["theme_no_icon_tint"]` also lack an explicit light-mode `modulate`, so they don’t have a reliable baseline tint and won’t be recolored when dark mode is enabled.

## Proposed Changes

### 1) Make the affected MainMenu icons tintable + set a light-mode baseline tint

Update [MainMenu.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainMenu.tscn) for these `TextureRect` nodes:

- Remove `groups=["theme_no_icon_tint"]`
- Add `modulate = Color(0.06666667, 0.09411765, 0.15294118, 1)` (current light palette “primary text” used throughout MainMenu labels)

Nodes to change (paths + current locations):

- `Background/MarginContainer/RootVBox/TopBar/Brand/BrandIcon/Icon` ([MainMenu.tscn:L657-L667](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainMenu.tscn#L657-L667))
- `Background/MarginContainer/RootVBox/MainCardsRow/HeroCard/.../HeroTitleRow/HeroAppIcon/Icon` ([MainMenu.tscn:L767-L777](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainMenu.tscn#L767-L777))
- `Background/MarginContainer/RootVBox/MainCardsRow/RecentSaveCard/.../ProfileRow/Avatar/AvatarIcon` ([MainMenu.tscn:L997-L1007](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainMenu.tscn#L997-L1007))
- `Background/MarginContainer/RootVBox/ActionsGrid/NewGame/Content/IconTile/Icon` ([MainMenu.tscn:L1189-L1199](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainMenu.tscn#L1189-L1199))
- `Background/MarginContainer/RootVBox/ActionsGrid/LoadGame/Content/IconTile/Icon` ([MainMenu.tscn:L1269-L1279](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainMenu.tscn#L1269-L1279))
- `Background/MarginContainer/RootVBox/ActionsGrid/Settings/Content/IconTile/Icon` ([MainMenu.tscn:L1349-L1359](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainMenu.tscn#L1349-L1359))
- `Background/MarginContainer/RootVBox/ActionsGrid/Quit/Content/IconTile/Icon` ([MainMenu.tscn:L1429-L1439](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainMenu.tscn#L1429-L1439))

Why this fixes it:

- Light mode: the baseline dark `modulate` makes white-stroke SVGs readable on the near-white icon tiles.
- Dark mode: DarkMode/ThemePreview are allowed to retint these TextureRects (since `theme_no_icon_tint` is removed), making them readable against dark backgrounds.

### 2) No DarkMode/ThemePreview code changes (expected)

Based on current implementation, DarkMode and ThemePreview already correctly tint `TextureRect` icons when they are not excluded by `theme_no_icon_tint`. The issue is localized to MainMenu scene data (node grouping + missing baseline tint).

## Assumptions & Decisions

- Keep all other MainMenu styling unchanged (icon tile styleboxes, spacing, layout).
- Use the existing light-mode primary text color already present throughout MainMenu (`Color(0.06666667, 0.09411765, 0.15294118, 1)`) as the baseline icon tint, rather than introducing new palette wiring into the scene file.
- Let DarkMode/ThemePreview pick the correct dark palette tint at runtime/in-editor; no new icon-specific groups are required for this fix.

## Verification Steps

- Editor verification:
  - Open `MainMenu.tscn` and confirm the affected icons are visible in light preview.
  - Toggle ThemePreview to dark palette and confirm those icons remain visible.
- Runtime verification:
  - Run the game, land on MainMenu, toggle dark mode (current hotkey), and confirm the affected icons are visible and not “washed out” or missing.
- Diagnostics:
  - Ensure there are no new GDScript parse/type warnings treated as errors.
