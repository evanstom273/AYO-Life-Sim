## Summary
- Build out the **middle panel (Life Log)** to match the reference image while leaving left sidebar, top bar, and right bar unchanged.
- Deliverables (per your choices):
  - Full timeline-style Life Log list (Year + Age, dot markers, subtle vertical line, right-aligned dates).
  - “Show More History” control at the bottom.
  - “Filters” becomes an **OptionButton** (dropdown UI only; no filtering logic yet).
  - Include **8 placeholder entries** to validate layout.

## Current State Analysis (Repo-Grounded)
- Middle panel container is: `ColorRect/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/PanelContainer` in [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn#L569-L633).
- Current middle structure:
  - Header exists with `Title` and `FiltersButton` (currently a `Button`) ([MainUI.tscn:L586-L610](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn#L586-L610)).
  - Scroll area exists, but it’s wrapped in a `Panel` and the `ScrollContainer` uses manual offsets (`layout_mode = 0` + negative offsets), which is fragile ([MainUI.tscn:L611-L627](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn#L611-L627)).
  - `LifeLogEntries` VBox exists but is empty ([MainUI.tscn:L624-L627](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn#L624-L627)).
  - A `BottomSpacer` exists (reserved space) ([MainUI.tscn:L629-L632](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn#L629-L632)).

## Decisions (Locked)
- Middle elements: **Timeline + Show More History** (no modal in this pass).
- Filters control: **OptionButton**.
- Timeline style: **Full timeline** (dot markers + subtle vertical line + right-aligned dates).
- Placeholders: **8 entries**.

## Proposed Changes (Decision-Complete)
### 1) Normalize the middle panel layout (remove manual offsets)
File: [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn)
- Remove or refactor the middle `Panel` wrapper so the scroll area uses container-based sizing:
  - Preferred: remove `CenterVBox/Panel` and move `ScrollContainer` to be a direct child of `CenterVBox`.
  - Set `ScrollContainer.layout_mode = 2`, `size_flags_vertical = EXPAND_FILL`, `size_flags_horizontal = EXPAND_FILL`.
  - Keep the middle panel background via the existing `PanelContainer` (already styled by `panel1.tres`).
- Ensure `LifeLogEntries` VBox remains the single child of the ScrollContainer and uses `theme_override_constants/separation = 12`.

Why:
- Eliminates brittle negative offsets and ensures the middle layout scales correctly with window resizing.

### 2) Replace “Filters” Button with an OptionButton (dropdown UI only)
File: [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn)
- Replace node `FiltersButton` (currently `Button`) with `OptionButton` while keeping the same placement in the header row.
- Add a few placeholder options (e.g., “All”, “Career”, “Relationships”, “Education”) so the dropdown behaves like the reference.
- Reuse the existing button styleboxes used for “Filters”:
  - `theme_override_styles/normal = StyleBoxFlat_filters_normal`
  - `theme_override_styles/hover/pressed = StyleBoxFlat_filters_hover`
- Keep sizing similar:
  - `custom_minimum_size.y ≈ 32`
  - Right aligned due to the existing spacer.

### 3) Build the timeline entry structure (reusable, clean hierarchy)
File: [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn)
- Under `LifeLogEntries`, add 8 entry nodes following a consistent template:
  - `LifeLogEntry` (HBoxContainer)
    - `YearLabel` (Label) — e.g., “2025”
    - `AgeLabel` (Label) — e.g., “Age 24”
    - `TimelineRail` (Control; fixed width ~16–20)
      - `Dot` (ColorRect; 6–8px circle approximation via StyleBoxFlat or small rounded panel)
      - `Line` (ColorRect; 2px wide; stretches vertically within the entry row)
    - `Content` (VBoxContainer; expand)
      - `TitleRow` (HBoxContainer)
        - `EventTitle` (Label; bold-looking via font size 14–16)
        - `Spacer` (Control; expand)
        - `DateLabel` (Label; small, muted, right aligned, e.g., “Mar 15”)
      - `Description` (Label; smaller muted body text; wraps)
- Spacing targets:
  - Entry vertical padding achieved via container separation (LifeLogEntries separation ~12) and internal VBox separation (6–8).
  - `YearLabel`/`AgeLabel` use consistent minimum widths so the columns align.
- Colors:
  - Primary text: #111827 (already used elsewhere as `Color(0.0667,0.0941,0.1529,1)`).
  - Muted text: #4B5563-ish for ages/descriptions/dates.
  - Timeline dot: blue accent #2563EB-ish; line: soft gray #E5E7EB-ish.

Notes:
- Use only standard Controls (no custom drawing). The rail is built from `ColorRect`s for the dot/line.
- Keep the node tree shallow: each entry is one HBox with small child containers.

### 4) Add “Show More History” control (bottom of middle)
File: [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn)
- Replace or repurpose `BottomSpacer`:
  - Insert a centered `Button` or `MenuButton` styled like the reference:
    - Text: “Show More History”
    - Optional dropdown affordance can be approximated with a `MenuButton` (no items needed yet) or kept as a Button for now.
  - Keep a small spacer below it (e.g., 16–24px) to preserve breathing room.

## Files To Change
- [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn)

## Assumptions & Constraints
- No filtering logic is implemented; only the dropdown UI for Filters exists.
- No modal (“Job Offer”) changes in this pass (explicitly excluded by your selection).
- Only the middle panel branch is edited; left sidebar and right bar remain untouched.

## Verification Steps
- Open [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn) in Godot and confirm:
  - Filters is an OptionButton and opens a dropdown.
  - ScrollContainer is layout-driven (no negative offsets) and scrolls properly.
  - 8 timeline entries render with aligned Year/Age columns, dot + subtle line rail, right-aligned dates, and wrapped descriptions.
  - “Show More History” control appears at the bottom of the middle panel.
  - No diagnostics in the editor.
