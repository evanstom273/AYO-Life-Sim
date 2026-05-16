## Summary
- Replace the console-only “Not enough energy” message in `consume_energy(amount)` with a modal **AcceptDialog** popup that blocks interaction until dismissed.
- Create and configure the popup dynamically in `_ready()` and store it in a new top-level variable: `var out_of_energy_popup: AcceptDialog`.

## Current State Analysis (Grounded)
- The script is [WeeklyCalendarCard.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/WeeklyCalendarCard.gd).
- `consume_energy(amount: int)` currently:
  - Decrements energy, prints success, and calls `_update_energy_ui()` when `current_energy >= amount` ([WeeklyCalendarCard.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/WeeklyCalendarCard.gd#L74-L79)).
  - Otherwise prints a failure message to the console ([WeeklyCalendarCard.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/WeeklyCalendarCard.gd#L79-L80)).
- No popup/modal currently exists in this script.

## Proposed Changes

### 1) Add a new popup variable at top-level
File: [WeeklyCalendarCard.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/WeeklyCalendarCard.gd)
- Declare near the other variables:
  - `var out_of_energy_popup: AcceptDialog`

### 2) Create/configure the AcceptDialog in `_ready()`
File: [WeeklyCalendarCard.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/WeeklyCalendarCard.gd)
- In `_ready()`:
  - `out_of_energy_popup = AcceptDialog.new()`
  - `out_of_energy_popup.title = "Out of Energy!"`
  - `out_of_energy_popup.dialog_text = "You are too exhausted to do anything else right now. You need to rest and let time pass before attempting more activities."`
  - `out_of_energy_popup.exclusive = true`
  - `add_child(out_of_energy_popup)`

### 3) Update `consume_energy()` to show the popup on failure
File: [WeeklyCalendarCard.gd](file:///c:/Users/evans/Documents/AYO-Life%20Sim/AYO-Life%20Sim/scripts/WeeklyCalendarCard.gd)
- Replace the failure `print(...)` branch with:
  - `out_of_energy_popup.popup_centered()`
  - Ensure the function does not spend energy or update the energy UI in this branch.
- Keep the success behavior unchanged:
  - Still prints success.
  - Still calls `_update_energy_ui()` after spending energy.

## Assumptions & Decisions
- The requested behavior “halts the player” is implemented via `AcceptDialog.exclusive = true` (modal) as specified.
- No other pause/`get_tree().paused` behavior is introduced since it wasn’t requested.
- The failure print is removed (replaced by the popup) per request.

## Verification Steps
- Open the game and trigger energy consumption:
  - Confirm success path still prints and updates the energy bar/label when energy is sufficient.
  - Reduce energy until it’s below the requested `amount`, then attempt again:
    - Confirm the **Out of Energy!** popup appears centered.
    - Confirm it must be dismissed via **OK** (modal/exclusive).
    - Confirm no “Not enough energy” failure print appears in the console.
