# Fix ThemePreview Color Alpha Compile Error (Plan)

## Summary
Fix the Godot 4.6 compile error in `ThemePreview.gd` caused by calling `Color.with_alpha()`, which doesn’t exist in this project’s Godot build. Replace it with a supported way to set alpha.

## Current State (Repo Truth)
- `scripts/theme/ThemePreview.gd` line ~334 uses:
  - `var disabled: Color = secondary.with_alpha(0.45)`
- Godot reports:
  - `Cannot find member "with_alpha" in base "Color"`

## Proposed Change
**File:** `scripts/theme/ThemePreview.gd`
- Replace `secondary.with_alpha(0.45)` with:
  - `var disabled: Color = secondary`
  - `disabled.a = 0.45`

No behavior change intended besides compiling successfully.

## Verification
- Confirm editor diagnostics are clean (no parse/compile errors).
- Open a scene with `ThemePreview` and ensure toggling preview still works.
