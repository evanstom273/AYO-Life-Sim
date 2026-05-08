## Summary
- Update the top bar in [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn) to visually match the provided reference image.
- Scope is strictly limited to the top bar row (and an optional thin divider directly beneath it); no other UI/content changes.

## Current State Analysis
- The project has a single scene: [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn).
- The current “top bar” is an `HBoxContainer` named `VBoxContainer2` under `ColorRect/MarginContainer/VBoxContainer/MarginContainer/`.
  - `PlayerName` contains a single long text row: `LIFE SIM / ALEX JOHNSON / AGE: 24 / YEAR: 2025`.
  - `PlayerFinances` contains: `Cash: $18,000 / POLICE OFFICER / UNIVERSITY DEgree`.
  - `Options` exists but has no children.
- No icon assets (SVG/PNG) exist in the repo to match the reference iconography; therefore the plan uses text/unicode glyphs for icons to avoid creating additional asset files.

## Reference Image: Top Bar Elements To Match
- Left cluster:
  - App title: “LifeSim” (title case).
  - Age and Year displayed as small metadata: “Age: 24 • Year: 2025”, optionally prefixed by a small calendar glyph.
- Middle cluster (visually centered in the bar):
  - Cash label with green amount: “Cash: $18,645” (amount tinted green).
  - Current job title (e.g., “Junior Marketing Specialist”), optionally prefixed by a briefcase glyph.
  - Current education (e.g., “Bachelor’s Degree”), optionally prefixed by a graduation-cap glyph.
- Right cluster:
  - Two small icon-like buttons: overflow menu (“…”) and settings (“⚙”).

## Proposed Changes (Concrete, File-Scoped)
### 1) Restructure the Top Bar Container
File: [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn)
- Keep the existing top bar wrapper `MarginContainer` at `ColorRect/MarginContainer/VBoxContainer/MarginContainer`.
- Replace the internal layout of `VBoxContainer2` to follow a 3-region structure:
  - **LeftGroup** (existing `PlayerName` repurposed)
  - **CenterGroup** (existing `PlayerFinances` repurposed and set to expand)
  - **RightGroup** (existing `Options` populated)
- Set spacing and size flags so the center group is visually centered between left and right.
  - `PlayerFinances.size_flags_horizontal = EXPAND_FILL` (so it takes remaining width)
  - Use `BoxContainer.alignment = CENTER` on `PlayerFinances` (Godot 4 `BoxContainer` alignment) so the cluster sits centered in its expanded area.
  - Increase `theme_override_constants/separation` on key HBoxContainers to match the airy spacing in the reference.

### 2) Update LeftGroup Content (App + Age/Year)
File: [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn)
- Replace the current slash-delimited labels with:
  - A `Label` for “LifeSim” (no forced uppercase).
  - A small spacer (or use container separation).
  - A compact metadata label for age/year:
    - Example text: `🗓  Age: 24  •  Year: 2025`
    - If unicode glyphs render poorly with the chosen font, fall back to plain text: `Age: 24  •  Year: 2025`.
- Ensure the left cluster reads as a single cohesive segment with subtle styling:
  - Title: slightly larger or heavier (via `theme_override_font_sizes/font_size` if available).
  - Metadata: slightly smaller and/or lower-contrast (via `modulate` / theme override color).

### 3) Update CenterGroup Content (Cash + Job + Education)
File: [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn)
- Replace the slash-delimited labels with three subgroups inside `PlayerFinances`:
  - **CashGroup** (`HBoxContainer`)
    - `Label`: “Cash:”
    - `Label`: “$18,645” with green tint (e.g., `modulate = Color(0.2, 0.6, 0.3, 1)`).
  - **JobGroup** (`HBoxContainer`)
    - `Label`: `💼` (optional) + `Junior Marketing Specialist`
  - **EducationGroup** (`HBoxContainer`)
    - `Label`: `🎓` (optional) + `Bachelor’s Degree`
- Keep text in title case (no `uppercase = true`) to match the reference.
- Set container separation so these read as distinct chunks with consistent padding.

### 4) Populate RightGroup (Options Buttons)
File: [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn)
- Add two `Button` nodes under `Options`:
  - Overflow: text “…” (or “⋯” if preferred for alignment)
  - Settings: text “⚙”
- Make them appear like icon buttons:
  - `flat = true`
  - Minimal padding via theme override constants (as needed)
  - Optional: set `focus_mode = NONE` if focus outlines are distracting (only if consistent with existing UI conventions elsewhere).

### 5) Optional: Add a Subtle Divider Under the Top Bar
File: [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn)
- If needed to match the reference, add an `HSeparator` directly beneath the top bar inside the same top bar wrapper `MarginContainer` so the change remains “top bar only”.

## Assumptions & Decisions
- No new image assets will be introduced for icons; the top bar will use unicode glyphs or plain text to approximate the reference icons.
- Only [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn) will be modified, and only within the top bar section.
- Text values (age/year/cash/job/education) will remain placeholders as currently present; this task is strictly visual/layout, not data binding.

## Verification Steps (After Execution)
- Open [MainUI.tscn](file:///c:/Users/evans/Documents/text-based-life-sim/scenes/main/MainUI.tscn) in the Godot editor and confirm the top bar:
  - Shows “LifeSim” at left, age/year metadata next to it.
  - Shows cash with green amount, plus job and education, in a centered middle cluster.
  - Shows two right-aligned icon-like buttons (“…” and “⚙”).
  - No other parts of the scene hierarchy/content change.
