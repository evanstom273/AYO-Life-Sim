## Summary
- Build the **rest of the right bar** (everything below the existing Stats card) to match the provided reference image.
- Add the missing right-bar cards: **Relationships**, **Career**, **Finances**, **Quick Actions**.
- Use **static placeholders** for now and **color-coded relationship statuses** like the mockup.
- Add **new SVG icons** using the **Lucide** icon set, and include a small attribution/license note.

## Current State Analysis
- Scene: [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn)
- Right bar container:
  - `ColorRect/MarginContainer/VBoxContainer/HBoxContainer/RightBar` ([MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn#L632-L645))
  - Contains `StatsCard` (already updated) followed by placeholder nodes:
    - `GridContainer2`, `GridContainer3`, `GridContainer4`, `GridContainer5` ([MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn#L900-L913))
- Existing icons available under `assets/icons/` (home/users/briefcase/grad_cap/heart/dollar/building/star/clock).
- Shared panel style: [panel1.tres](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/ui/panels/panel1.tres) is already a light panel with subtle border and rounded corners.

## Decisions (Locked)
- Sections to add below Stats: **Relationships + Career + Finances + Quick Actions** (all 4).
- Icons: **Add new icons** to match the mockup style; icon set: **Lucide**.
- Data: **Static placeholders** for now (matching the reference style).
- Relationships statuses: **Color-coded**.
- Scope constraint: modify **only the right bar content below Stats**, plus add needed icon assets and attribution.

## Proposed Changes
### 1) Replace placeholder right-bar nodes with real cards
File: [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn)
- Under `RightBar/MarginContainer/VBoxContainer`:
  - Keep `StatsCard` unchanged.
  - Remove `GridContainer2`–`GridContainer5`.
  - Add, in order:
    1) `RelationshipsCard` (PanelContainer)
    2) `CareerCard` (PanelContainer)
    3) `FinancesCard` (PanelContainer)
    4) `QuickActionsCard` (PanelContainer)
- Each card structure (consistent, maintainable):
  - `PanelContainer` (uses `theme_override_styles/panel = ExtResource("1_c6qpx")`)
    - `MarginContainer` (padding 16)
      - `VBoxContainer` (separation 10–12)
        - Header `HBoxContainer`:
          - `TextureRect` icon (16×16, tinted muted gray)
          - `Label` title (e.g., “Relationships”)
        - Content container (varies per card)

### 2) Relationships card (mockup-style table)
File: [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn)
- Content layout: `GridContainer` with 3 columns:
  - Column 1: relationship type (Mother, Father, Partner, Best Friend, Child)
  - Column 2: person name (Emma, Daniel, Jordan, Taylor, —)
  - Column 3: status (Close, Close, Dating, Close, None) right-aligned
- Status colors (match mockup intent):
  - Close: green (e.g., #16A34A)
  - Dating: blue (e.g., #2563EB)
  - None: gray (e.g., #6B7280)

### 3) Career card (title + salary + performance bar + education row)
File: [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn)
- Content:
  - Top `HBoxContainer`: left `VBoxContainer` (Job Title, Company), right salary label (e.g., “$52,000 / yr”)
  - Performance row: label “Performance”, progress bar, percent label (e.g., 72%)
  - Education row: label “Education”, value label (“Bachelor’s Degree”)
- Progress bar styling:
  - Use the same progress bar style approach as Stats (thin bar, no percentage text inside bar), but keep it simple and consistent.

### 4) Finances card (3-row key/value with colored numbers)
File: [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn)
- Rows:
  - Bank Balance: $18,645 (green)
  - Monthly Income: $4,333 (green)
  - Monthly Expenses: $2,950 (red)
- Layout: 2-column grid (label left, value right-aligned).

### 5) Quick Actions card (2-column button grid with icons)
File: [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn)
- Layout: `GridContainer` with 2 columns, 3 rows of buttons:
  - Age Up
  - Study
  - Work Hard
  - Go to Doctor
  - Call Friend
  - Browse Jobs
- Button styling:
  - Reuse the existing “Filters” button styleboxes (`StyleBoxFlat_filters_normal`/`hover`) for a clean outlined/soft button look, or introduce a dedicated `StyleBoxFlat_quick_action_*` if the padding differs.
  - Each button uses an icon (16×16) tinted blue/gray consistent with the mockup.

### 6) Add new Lucide SVG icons + attribution
Files:
- Add needed SVGs under `assets/icons/` (Lucide):
  - For card headers: `bar-chart-3.svg` (Stats, if needed later), `users.svg` (already exists), `briefcase.svg` (exists), `dollar-sign.svg` (may map to existing `dollar.svg`), `zap.svg` (Quick Actions)
  - For quick actions: `clock.svg` (exists), `book-open.svg`, `hammer.svg`, `stethoscope.svg`, `phone.svg`, `search.svg`
- Add attribution file:
  - `assets/icons/ICON_LICENSES.txt` (short note: Lucide source + license; no extra prose)

Notes:
- Only add icons that are actually used by the new right-bar cards/buttons.
- Prefer reusing existing icons where a direct Lucide match already exists in the repo (e.g., users/briefcase/clock), but switch to Lucide versions if current ones don’t match visually.

## Assumptions & Constraints
- “Rest of the right bar” means everything below `StatsCard` inside `RightBar/MarginContainer/VBoxContainer`.
- No gameplay logic; buttons won’t be wired yet (pure UI structure).
- No changes to left sidebar, top bar, center Life Log, or Stats card.

## Verification Steps
- Open [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn) and confirm:
  - Right bar shows, below Stats: Relationships, Career, Finances, Quick Actions in the correct order.
  - Layout, spacing, and typography resemble the reference (clean dashboard cards).
  - Relationships statuses are color-coded.
  - Quick Actions render as a 2-column grid of buttons with icons.
  - No diagnostics in the editor.
