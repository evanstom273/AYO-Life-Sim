# Fix WeeklyCalendarCard Typed GDScript Warnings (Plan)

## Summary
Fix the “warnings treated as errors” GDScript typing issues in `WeeklyCalendarCard.gd` by making the inferred values explicitly typed (use `clampi()` and typed String extraction), so the script compiles cleanly under strict typing.

## Current State Analysis (Repo Truth)
- The errors reference `scripts/WeeklyCalendarCard.gd`:
  - “Cannot infer the type of `month` variable…”
  - “variable type is being inferred from a Variant value…”
- In the current script, `_update_labels()` uses `clamp(...)` inside array indexing and string formatting, which can cause Variant inference:
  - `var month := MONTH_NAMES[clamp(month_index, 0, 11)]`
  - `clamp(week_index, 1, 4)` in formatting

## Proposed Changes

### 1) Make month/week computations explicitly typed
**File:** `c:/Users/evans/Documents/text-based-life-sim/scripts/WeeklyCalendarCard.gd`

Update `_update_labels()` to:
- Use `clampi()` (int clamp) instead of `clamp()` so the result is an `int`.
- Store intermediate values with explicit types:
  - `var mi: int = clampi(month_index, 0, 11)`
  - `var wi: int = clampi(week_index, 1, 4)`
  - `var month: String = MONTH_NAMES[mi]`
- Use `wi` in the helper string.

Update `_update_week_pressed()` similarly:
- `var target: int = clampi(week_index, 1, 4)`

### 2) (Optional hardening) Type the month name list
If the compiler still treats `MONTH_NAMES[...]` as Variant, change the declaration to a typed container:
- `const MONTH_NAMES: PackedStringArray = PackedStringArray(["Jan", ...])`

This makes the index expression return a `String` deterministically.

## Assumptions & Constraints
- No behavior change intended: only typing/compilation fixes.
- Keep UI behavior identical (month cycling, year wrap, week reset).

## Verification
- Re-run Godot with warnings-as-errors enabled and confirm no script compile errors.
- Confirm:
  - Month label updates when clicking ‹/›
  - Week selection still updates helper text
  - Month change still resets to Wk1
