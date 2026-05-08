## Summary
- Turn the **left sidebar buttons** in [MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn) into a **single-select “tab” navigation**.
- Make the **center panel** swap between 9 tab pages (placeholders for now).
- Keep **Overview** showing the current UI; keep the center header text **“Life Log”** on Overview; on other tabs the header shows the tab name.
- Make the **right bar** visible **only on Overview**; on other tabs it collapses so the center expands.

## Current State Analysis (Grounded)
- The scene root is a `Control` named `Control` in [MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn#L2307).
- Left sidebar nav buttons exist but have **no navigation logic** (no script attached to the scene root and no signal connections).
  - Buttons are under `ColorRect/MarginContainer/VBoxContainer/HBoxContainer/PanelContainer/MarginContainer/VBoxContainer`:
    - `Home` (label “Overview”), `Relationships`, `Career`, `Education`, `Health`, `Finances`, `Assets`, `Activities`, `History` ([MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn#L2505-L2746)).
- The “Life Log” UI currently lives in the middle card:
  - `.../HBoxContainer/MarginContainer/PanelContainer/CenterMargin/CenterVBox/Header/Title` has `text = "Life Log"` ([MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn#L2922-L2933)).
- The right bar is a `PanelContainer` named `RightBar` and is currently always present ([MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn#L4126-L4139)).
- A `ButtonGroup` pattern is already used elsewhere in this scene (calendar week buttons), so using a `ButtonGroup` for sidebar selection matches existing conventions ([MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn#L3910-L4012)).

## Decisions Locked (From You)
- Clicking a left sidebar item changes **center + right**.
- Sidebar behaves like **real tabs** (single-select, one stays highlighted).
- No visible tab bar; the current section appears where the center header title is now.
- **Overview** keeps the current header text **“Life Log”**.
- Non-Overview pages are **placeholders first** (title + “coming soon” message).
- Right bar is **only visible on Overview** and **collapses** on other tabs.
- All 9 sidebar buttons are available immediately; **History exists as a tab but is placeholder/blank**.
- Default selected tab on open: **Overview**.

## Proposed Changes

### 1) Add a MainUI controller script (navigation brain)
File: [scripts/MainUI.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts)
- Create a new script attached to the scene root `Control` that:
  - Maps each sidebar button to a tab index (Overview, Relationships, Career, Education, Health, Finances, Assets, Activities, History).
  - On selection change:
    - Switches the center content container to the matching tab page.
    - Updates the center header title:
      - Overview → “Life Log”
      - Otherwise → selected tab name
    - Shows `RightBar` + `VSeparator2` only when Overview is active; hides both otherwise.
    - Shows the “Filters” control only on Overview (hide it on other tabs).

### 2) Convert left sidebar nav buttons into a single-select tab group
File: [MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn)
- Add a new `ButtonGroup` subresource (e.g. `ButtonGroup_sidebar_nav`).
- For each of the 9 nav buttons (`Home`, `Relationships`, `Career`, `Education`, `Health`, `Finances`, `Assets`, `Activities`, `History`):
  - Set `toggle_mode = true`
  - Assign `button_group = SubResource("ButtonGroup_sidebar_nav")`
- Set `Home.button_pressed = true` so Overview is selected on load.

### 3) Make the center area swappable (tab pages)
File: [MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn)
- Keep the existing center card `PanelContainer` and its `Header` as the shared “breadcrumb/title” area.
- Under `CenterVBox`, replace the “body” portion with a `TabContainer` (tabs hidden) that contains 9 pages:
  - `OverviewPage`: contains the current Overview body content (everything that is currently under `CenterVBox` **except** `Header`).
  - `RelationshipsPage`, `CareerPage`, `EducationPage`, `HealthPage`, `FinancesPage`, `AssetsPage`, `ActivitiesPage`, `HistoryPage`: placeholder UIs:
    - A `VBoxContainer` with:
      - A `Label` like “Coming soon”
      - (Optional) a smaller label for a one-line description if needed later
- Ensure the Overview body layout remains visually identical when the Overview tab is selected.

### 4) Wire the scene root to the script
File: [MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn)
- Add an `ext_resource` entry for `res://scripts/MainUI.gd`.
- Attach it to the root `[node name="Control" type="Control" ...]` via `script = ExtResource("...")`.

## Assumptions & Constraints
- No gameplay/data logic is added for non-Overview tabs yet; placeholders only.
- No new assets required.
- Keep existing UI styling/structure as much as possible; only restructure the center card enough to support tab pages.
- Avoid adding comments.

## Verification Steps
- In Godot, open [MainUI.tscn](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scenes/main/MainUI.tscn) and verify:
  - Default selected nav item is **Overview** (Home button stays selected).
  - Clicking each sidebar button:
    - Switches the center content to the correct placeholder page.
    - Updates the center header title (“Life Log” on Overview; tab name on others).
    - Hides the Filters control on non-Overview tabs.
    - Collapses the right bar (and its separator) on non-Overview tabs; center expands.
  - Clicking back to Overview restores:
    - The existing “Life Log” overview UI exactly as before
    - The right bar visible again
