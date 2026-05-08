# Fix WeeklyCalendarCard MONTH_NAMES Constant (Plan)

## Summary
Fix the compile error `Assigned value for constant "MONTH_NAMES" isn't a constant expression` in `WeeklyCalendarCard.gd` by replacing the `PackedStringArray(...)` constructor call with a constant array literal that GDScript accepts as a constant expression.

## Current State Analysis (Repo Truth)
- `scripts/WeeklyCalendarCard.gd` currently declares:
  - `const MONTH_NAMES: PackedStringArray = PackedStringArray([...])`
- In Godot 4.6, calling `PackedStringArray(...)` is not considered a constant expression, so the script fails to compile.

## Proposed Changes
**File:** `c:/Users/evans/Documents/text-based-life-sim/scripts/WeeklyCalendarCard.gd`

1) Replace the constant definition with a constant typed array literal:
- Change to:
  - `const MONTH_NAMES: Array[String] = ["Jan", "Feb", ..., "Dec"]`

2) Keep the existing explicit typing in `_update_labels()`:
- `var month: String = MONTH_NAMES[mi]`

No behavior changes intended; only compilation correctness.

## Verification
- Re-open/run the project and confirm:
  - No script compile errors.
  - Month cycling and helper label still work as before.
