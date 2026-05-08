## Summary

Improve the visual “material” of UI panels/cards across all UI scenes by introducing subtle gradient background textures (light + dark), then wiring them into existing card/panel styleboxes and the light/dark preview + runtime dark mode systems.

## Current State Analysis

- Panels/cards are currently rendered with `StyleBoxFlat` (solid `bg_color` + `border_color`), either:
  - as a shared resource: [panel1.tres](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/ui/panels/panel1.tres), or
  - as inline `sub_resource StyleBoxFlat` blocks inside scenes like [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn) and [MainMenu.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainMenu.tscn).
- There are no existing UI background textures, shader materials, or `StyleBoxTexture` resources in the repo (icons are SVG-only).
- Dark mode + editor preview currently recolor panels/cards by duplicating `StyleBoxFlat` and changing `bg_color`/`border_color`:
  - Runtime: [DarkMode.gd](file:///c:/Users/evans/Documents/text-based-life-sim/scripts/DarkMode.gd#L224-L279)
  - Editor: [ThemePreview.gd](file:///c:/Users/evans/Documents/text-based-life-sim/scripts/theme/ThemePreview.gd#L226-L257)
- Theme palettes exist and are used consistently: [palette_light.tres](file:///c:/Users/evans/Documents/text-based-life-sim/resources/theme/palette_light.tres), [palette_dark.tres](file:///c:/Users/evans/Documents/text-based-life-sim/resources/theme/palette_dark.tres)

## Proposed Changes

### 1) Add gradient background texture assets (SVG)

Create 4 SVG assets (text-based, easy to version and tweak) with rounded corners + very subtle top highlight / bottom shade to add depth:

- `res://assets/ui/panel_bg_light.svg`
- `res://assets/ui/panel_bg_dark.svg`
- `res://assets/ui/card_bg_light.svg`
- `res://assets/ui/card_bg_dark.svg`

Design rules for each SVG:
- Rounded rect radius matches current style intent (≈ 12–14px).
- Border is subtle but present (baked in the SVG so it looks good without relying on `StyleBoxFlat.border_color`).
- Gradient is low-contrast (a “material” hint, not a noisy pattern).

### 2) Introduce shared StyleBoxTexture resources (light + dark, panel + card)

Add 4 `StyleBoxTexture` resources pointing at those SVGs:

- `res://resources/ui/styleboxes/panel_light.tres`
- `res://resources/ui/styleboxes/panel_dark.tres`
- `res://resources/ui/styleboxes/card_light.tres`
- `res://resources/ui/styleboxes/card_dark.tres`

Each stylebox will:
- Use the SVG as its `texture`
- Set `content_margin_*` to match existing padding expectations (align with current 12–24px margins used in scenes)
- Use stretch settings that preserve corner fidelity (no tiling artifacts)

### 3) Update existing shared card style to use the new textured look

Update [panel1.tres](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/ui/panels/panel1.tres) so it becomes the canonical “card” look for light mode by switching it to (or replacing it with) the new `StyleBoxTexture` card style:

- Option A (preferred): keep `panel1.tres` but convert it to `StyleBoxTexture` and point it at `card_bg_light.svg` (minimal scene churn because multiple scenes already reference `panel1.tres`).
- If Godot serialization makes direct conversion awkward, replace usages in scenes with `resources/ui/styleboxes/card_light.tres` instead and keep `panel1.tres` as a legacy fallback.

Scenes that benefit immediately (already reference `panel1.tres`):
- [Settings.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/Settings.tscn)
- [NewGame.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/NewGame.tscn)
- [LoadGame.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/LoadGame.tscn)

### 4) Wire dark mode + editor preview to swap textured styleboxes

Extend both systems so that when a control’s `"panel"` style is a textured card/panel, switching palettes swaps to the matching light/dark `StyleBoxTexture`:

- Runtime: [DarkMode.gd](file:///c:/Users/evans/Documents/text-based-life-sim/scripts/DarkMode.gd)
  - In the panel style application path, detect when the base/current `"panel"` stylebox is one of the textured styles (or matches our texture assets), and override `"panel"` with `panel_dark.tres`/`card_dark.tres` when dark mode is enabled.
  - Preserve the existing restore cache behavior so toggling doesn’t compound overrides.
- Editor: [ThemePreview.gd](file:///c:/Users/evans/Documents/text-based-life-sim/scripts/theme/ThemePreview.gd)
  - Mirror the same swap logic based on `preview_dark`.

Selection of panel-vs-card remains the existing group-based heuristic:
- `theme_panel` → panel texture
- `theme_card` (and default heuristic for small cards) → card texture

### 5) Apply textured panel/card style across major scenes (hybrid approach)

Update scene data to use the new shared styleboxes where it’s clean and high-impact, while leaving a few special cases alone:

- [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn)
  - Identify the main card/panel containers (Stats, Life Log, Relationships, etc.) and point their `theme_override_styles/panel` at `card_light.tres` or `panel_light.tres` rather than bespoke inline `StyleBoxFlat` where possible.
  - Keep any intentionally unique “selected”/accented panels using existing overrides (so UX state remains obvious).
- [MainMenu.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainMenu.tscn)
  - Apply `card_light.tres` to the primary cards (HeroCard, RecentSaveCard) and `panel_light.tres` where it reads better.
  - Keep icon tile styling either as-is or convert it to the card texture depending on visual result (still within “panels/cards” scope).
- Any remaining UI scenes that have obvious main cards/panels will be updated similarly (without reworking layout or adding nodes).

## Assumptions & Decisions

- “Texture” means a subtle gradient material (not noise) and should remain readable behind text and icons.
- Apply improvements to both light and dark modes, and keep Ctrl+D + ThemePreview consistent.
- Prefer shared resources for maintainability, but allow a small number of scene-specific exceptions (hero cards, special highlight states).
- No layout changes; only visuals (styleboxes, colors, highlights).

## Verification Steps

- Editor:
  - Open MainUI/MainMenu/Settings/NewGame/LoadGame and confirm cards/panels show the gradient material in light mode.
  - Toggle ThemePreview dark and confirm the textured cards/panels swap to the dark versions and remain readable.
- Runtime:
  - Run and toggle dark mode; confirm cards/panels swap consistently and there is no flicker/compounding styling after multiple toggles.
- Diagnostics:
  - Ensure no new GDScript warnings/errors (typed warnings treated as errors in this project).
