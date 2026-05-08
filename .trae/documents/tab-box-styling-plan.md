## Summary
- Restyle the **large dark grey inner box** shown on **non-Overview tabs** (Relationships/Career/Education/Health/Finances/Assets/Activities/History) so it reads as a proper “card” and not a flat placeholder.
- Replace the current top-left placeholder labels with a **centered empty-state** (icon + message), using **per-tab semantic accent colors**.

## Current State Analysis (Grounded)
- Non-Overview tab content is shown via `ContentTabs` (`TabContainer`) under:
  - `ColorRect/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/PanelContainer/CenterMargin/CenterVBox/ContentTabs`
  - See [MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn#L4145-L4305).
- `ContentTabs` currently has **no** custom panel style override, so it uses the default TabContainer panel styling (the “boring dark grey box” in the screenshot).
- Placeholder pages currently contain simple labels (e.g., `RelationshipsPage/Title`, `RelationshipsPage/Message`) which sit at the top-left and don’t look like a designed empty-state.
- The project already has reusable dark-mode StyleBoxes we can apply:
  - Card style: [card_dark.tres](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/resources/ui/styleboxes/card_dark.tres)
  - Panel style: [panel_dark.tres](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/resources/ui/styleboxes/panel_dark.tres)
- A CenterContainer-based “card in the middle” pattern is used in other scenes (e.g. Settings), so it’s consistent to use for centered placeholder content:
  - [Settings.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/Settings.tscn#L99-L120)

## Decisions Locked (From You)
- Scope: **Non-Overview tabs only** (Overview remains unchanged).
- Styling: The boring box should look like a **card**.
- Placeholder layout: **Centered empty-state**.
- Accents: **Per-tab semantic colors**.
- History: **Show empty-state message** (not blank).

## Proposed Changes

### 1) Style the tab “box” as a card
File: [MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn)
- Update `ContentTabs` to draw like a card by setting:
  - `theme_override_styles/panel = ExtResource("21_card_dark")`
- Result: the big inner area inherits the same textured/rounded card background used elsewhere, instead of a flat grey rectangle.

### 2) Replace placeholder labels with a centered empty-state per tab
File: [MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn)
- For each non-Overview page:
  - `RelationshipsPage`
  - `CareerPage`
  - `EducationPage`
  - `HealthPage`
  - `FinancesPage`
  - `AssetsPage`
  - `ActivitiesPage`
  - `HistoryPage`
- Replace the current `Title` + `Message` labels with a centered layout:
  - Add child `Center` (`CenterContainer`) that fills the page (`size_flags_horizontal = 3`, `size_flags_vertical = 3`)
  - Inside `Center`, add `EmptyState` (`VBoxContainer`) containing:
    - `Icon` (`TextureRect`) using the matching sidebar icon for the tab
    - `Headline` (`Label`) with text like “Coming soon”
    - `Subtext` (`Label`) with a short per-tab sentence (e.g., “Career features will appear here.”)
- Apply semantic accents by tinting the icon via `Icon.modulate` (and optionally the headline color if desired):
  - Career: use the existing accent blue family
  - Finances: use the existing money green
  - Health: use the existing danger red
  - Education / Assets: use the existing warning orange (or a nearby gold tone)
  - Relationships / Activities / History: choose tasteful complementary colors that remain readable on dark backgrounds

### 3) Keep the header behavior unchanged
File: [scripts/MainUI.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/MainUI.gd)
- No changes required for behavior:
  - Header title continues to show the tab name on non-Overview tabs.
  - Overview stays “Life Log”.
  - Right bar continues to collapse on non-Overview tabs.

## Assumptions & Constraints
- No new gameplay/data logic is added; this is styling + placeholder presentation only.
- Reuse existing icon textures already referenced in `MainUI.tscn` and existing StyleBoxes (`card_dark.tres`).
- Avoid changes to Overview layout.

## Verification Steps
- Open [MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn) in Godot and verify:
  - Non-Overview tabs no longer show a flat grey inner box; the background reads as a card.
  - Each non-Overview tab shows a centered empty-state with the correct icon and accent tint.
  - Overview (Life Log) looks unchanged.
  - Switching tabs still hides the right bar on non-Overview tabs.
