# Implementation checkpoint

## Completed gate: schemas + validation

Godot 4 typed authored Resources and plain `RefCounted` runtime state are in place. No combat commands or transitions are implemented.

Added definitions: `data/definitions/{terrain_def,battle_map_def,battle_balance_def,force_preset_def}.gd`; retained `unit_type_def.gd`. Added state: `domain/{battle_state,side_state,squad_state,combatant_state}.gd`; validator: `domain/battle_validator.gd`; runner: `tests/run_validation_tests.gd`. Shipped hypotheses: `data/unit_types/{guard,striker,archer}.tres`, `data/terrain/{plain,rough,blocked}.tres`, `data/maps/open_field.tres`, `data/balance/default.tres`, `data/forces/guard_archer.tres`.

Schema choices: a map stores one default terrain ID and paired cell/terrain-ID overrides; this keeps the 9×7 authored map small. Squad type is an ID and all members must share it. Member `max_hp` is a runtime scalar checked against the unit definition plus the centralized commander bonus. The preset lists squad types for one side and can be applied symmetrically. `seed` is stored for later replay, with no RNG engine. Balance values are direct fields without min/default/max metadata, so there are no metadata bounds to check yet. `outcome` is a placeholder (`ongoing`, `blue`, `red`, `draw`).

Validation covers definition IDs and references, numeric bounds, map dimensions/cells/spawns, setup spawn legality, roster structure, entity IDs, HP, front membership, occupied cells, action pool and active/dead consistency. The runner loads shipped resources, accepts a valid setup, rejects several deliberately invalid definitions/maps/states and exits nonzero on a failed assertion.

## Verification

Using `C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe`:

```powershell
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --editor --import --quit
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/run_validation_tests.gd
```

Import exited 0. Validation runner exited 0 and printed `Validation tests passed` after a missing map validation method was fixed.

Next gate: pure command legality and state transitions.
