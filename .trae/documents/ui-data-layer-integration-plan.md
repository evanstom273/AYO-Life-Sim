# UI ↔ Data Layer Integration Plan (MainUI + PeopleResource)

## Summary

Connect `MainUI` to the player data layer (`PeopleResource`) so the main HUD initializes from `player_data` and stays consistent with the Weekly Calendar header, while preserving the existing pause + out-of-energy flow.

This plan implements:

1. Add `birth_month` to `PeopleResource` (in `PersonData.gd`).
2. Export `player_data: PeopleResource` on `MainUI.gd`.
3. Populate header/meta, stat bars, finances, and career/education labels from `player_data` during `MainUI._ready()` (null-safe).
4. Ensure pause + next-week cycle behavior remains correct (and validate it in-game).

## Current State Analysis

### Data layer

- `scripts/data/PersonData.gd` defines `class_name PeopleResource` and holds player fields:
  - Identity: `person_name`, `person_age`, `person_gender`, etc.
  - Stats: `Health`, `Happiness`, `Smarts`, `Looks`, `Fitness`, `Stress` (note: `Stress` is currently exported as -100..100).
  - Finances: `bank_balance`
  - Career: `current_job: JobResource` with `salary` in `scripts/data/JobData.gd`.
  - Education: `current_education`, `highest_education_completed` (enum values only; no string helpers yet).

### UI layer (MainUI)

- `scripts/MainUI.gd` currently handles only navigation/show-hide behavior; it has no player data wiring.
- UI nodes to populate live in `scenes/main/MainUI.tscn`, including:
  - Top “Meta” header label: `ColorRect/.../PlayerName/Meta`
  - Top strip: `CashAmount`, `JobTitle`, `EducationTitle`
  - Right panel: Stats progress bars + values; Finances card values; Career card job/education labels.

### Weekly calendar header ownership

- `scripts/WeeklyCalendarCard.gd` currently updates the top header Meta label in `_update_labels()`, but the player name/age portion is hard-coded.
- `WeeklyCalendarCard.gd` already implements:
  - ESC pause overlay + `set_energy_paused()`
  - “OUT OF ENERGY!” overlay + Next Week button
  - `advance_time()` and `reset_energy()` flow

## Assumptions & Decisions

- “Year” display uses the calendar year from `WeeklyCalendarCard.year` (not derived from age). (Per your selection.)
- Monthly Income comes from `player_data.current_job.salary` (or 0 if no job). Monthly Expenses default to 0 until an expenses system exists. (Per your selection.)
- The Weekly Calendar card owns updating the top Meta label over time; `MainUI` only injects player name/age and starting month. (Per your selection.)
- Starting month uses `player_data.birth_month` mapped to `WeeklyCalendarCard.month_index = birth_month - 1`.
- No `.tscn` edits are required; changes are limited to scripts + resource schema.

## Proposed Changes

### 1) Add `birth_month` to PeopleResource

**File:** `scripts/data/PersonData.gd`

- Add a new exported field in the “Person Info” group immediately after `person_gender`:
  - `@export_range(1, 12, 1) var birth_month: int = 1`
- Keep default at `1` so existing `.tres` resources load without edits.

### 2) Export `player_data` on MainUI

**File:** `scripts/MainUI.gd`

- Add, near the top before `@onready` vars:
  - `@export var player_data: PeopleResource`

This allows the `MainUI` scene instance to be wired to a `PeopleResource` via inspector.

### 3) Wire up Dynamic UI Initialization in MainUI._ready()

**File:** `scripts/MainUI.gd`

Add null-safe initialization:

- If `player_data == null`, do nothing (retain current placeholder UI).
- Else populate the following node values from `player_data`:

**Header / top strip**

- Update `Meta` label via the calendar card (not directly):
  - Provide player name + age to `WeeklyCalendarCard` through a small public API (see next section).
  - Set calendar starting month based on `player_data.birth_month`.

- Update top strip finances/career/education:
  - `CashAmount` → format from `player_data.bank_balance`
  - `JobTitle` → `player_data.current_job.job_name` (or “Unemployed”)
  - `EducationTitle` → human-readable string based on `player_data.highest_education_completed`

**Stat bars (right panel StatsCard)**

- Set `ProgressBar.value` + `Value.text` for:
  - Happiness, Health, Smarts, Looks, Fitness: clamp to 0..100
  - Stress: map from -100..100 into 0..100 (e.g., `(Stress + 100) / 2`) and clamp

Target nodes in `MainUI.tscn`:
- `.../StatsCard/.../Rows/HappinessRow/Bar` and `.../HappinessRow/Value`
- `.../Rows/HealthRow/Bar` and `.../HealthRow/Value`
- `.../Rows/SmartsRow/Bar` and `.../SmartsRow/Value`
- `.../Rows/LooksRow/Bar` and `.../LooksRow/Value`
- `.../Rows/FitnessRow/Bar` and `.../FitnessRow/Value`
- `.../Rows/StressRow/Bar` and `.../StressRow/Value`

**Finances (right panel FinancesCard)**

- Update:
  - `BankValue` → `player_data.bank_balance`
  - `IncomeValue` → `player_data.current_job.salary` or 0
  - `ExpensesValue` → 0 for now

Target nodes in `MainUI.tscn`:
- `.../FinancesCard/.../Grid/BankValue`
- `.../FinancesCard/.../Grid/IncomeValue`
- `.../FinancesCard/.../Grid/ExpensesValue`

**Career/Education (top strip + right panel CareerCard)**

- Right panel:
  - Career job title label: `.../CareerCard/.../JobInfo/JobTitle`
  - Education degree label: `.../CareerCard/.../EducationRow/EducationValue`

**Formatting helpers (inside MainUI.gd)**

- Add small private helpers:
  - `_format_money(amount: float) -> String` (e.g., “$18,645”)
  - `_education_level_to_text(level: PeopleResource.EducationLevel) -> String`
  - `_job_title_text(job: JobResource) -> String`
  - `_clamp_0_100(value: float) -> float`

### 4) Make WeeklyCalendarCard accept player name/age and starting month

**File:** `scripts/WeeklyCalendarCard.gd`

To keep CalendarCard as the single owner of the Meta label updates (and remove hard-coded “ADAM JOHNSON / Age: 24”):

- Add player fields to the calendar card:
  - Prefer a method-based API (so `MainUI` can safely call it with `has_method()`):
    - `func set_player_info(name: String, age: int) -> void`
    - Store into private vars (e.g., `_player_name`, `_player_age`)
- Add a public method to set the current time indices and refresh labels:
  - `func set_time(new_year: int, new_month_index: int, new_week_index: int) -> void`
  - Clamp values, update pressed week state, and call `_update_labels()`.
- Update `_update_labels()` to build the Meta label string using `_player_name` and `_player_age` rather than hard-coded values.

MainUI will then:
- Call `calendar_card.set_player_info(player_data.person_name, player_data.person_age)`
- Call `calendar_card.set_time(calendar_card.year, player_data.birth_month - 1, 1)` (or set month/week and refresh)

### 5) Finalize Pause & Next Week UI Flow (verification + minimal code touch)

**Files:** `scripts/WeeklyCalendarCard.gd`, `scripts/MainUI.gd` (only if required)

- Validate that:
  - ESC toggles `PauseOverlay` and correctly pauses energy drain (`set_energy_paused(true/false)`).
  - When energy hits 0:
    - `DepletedOverlay` appears and dims background (ColorRect alpha).
    - “Next Week” button advances time and begins a new energy cycle (via `advance_time(1)` → `reset_energy()`).
- Only change code if the runtime test shows a mismatch (current implementation already appears to satisfy the requirements).

## Verification Steps

1. Open `MainUI.tscn`, assign a `PeopleResource` instance to `MainUI.player_data` in the inspector, and set:
   - `person_name`, `person_age`, `birth_month`
   - Stats and `bank_balance`
   - Optional `current_job` with `job_name` and `salary`
2. Run the scene/game and verify on load (Overview):
   - Meta header shows the correct player name/age and Month starts from `birth_month`.
   - Stat bars match resource values.
   - Cash/Bank/Income/Expenses labels match expected formatted values.
   - Job title and education show in both top strip and right panel.
3. Pause flow:
   - Press ESC: pause overlay appears, energy drain stops.
   - Press Resume: overlay hides, energy drain resumes.
4. Depletion flow:
   - Wait until energy reaches 0: overlay appears and background dims.
   - Press Space or click “Next Week”: overlay disappears, energy resets, and week/month/year increment correctly.

