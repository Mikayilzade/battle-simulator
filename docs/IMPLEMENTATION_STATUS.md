# Implementation checkpoint

## Completed gate: schemas + validation

This gate introduced Godot 4 typed authored Resources and plain `RefCounted` runtime state, before combat commands and transitions were added.

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

## Completed gate: pure command legality + state transitions

Added `domain/battle_command.gd` for MOVE, ATTACK, GUARD, SET_FRONT and PASS, and `domain/battle_rules.gd` for legal commands, copy-on-write command application, explicit activation/round boundaries, deterministic path costs, line of sight, damage, front replacement and outcome checks. `BattleState` now tracks squad IDs already activated this round; `BattleValidator` checks them. Added `tests/run_command_tests.gd`.

Reversible choices: command application returns `{ok, state, error, events}` and never mutates its input. The caller chooses which living squad starts next; scheduling order belongs to the next gate. `finish_round` requires every living squad to have activated and applies the round cap. Movement accepts any valid orthogonal path within budget; `legal_commands` offers one stable cheapest path per reachable destination. Ranged sight is blocked by blocked terrain, including cells touching a diagonal corner; squads do not block sight. A manual front remains until changed or killed, including across activations. Attack markers remain valid after an attacker dies because they record past actions. The casualty-during-activation test injects a wound into a fixture: current deterministic attacks have no counterattack, so a legally active squad cannot otherwise receive a wound during its own activation yet.

Using `C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe`, the following commands were run for this gate:

```powershell
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --editor --import --quit
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/run_validation_tests.gd
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/run_command_tests.gd
```

Import and both test runners exited 0. Final outputs: `Validation tests passed` and `Command transition tests passed`.

Next gate: deterministic scheduler / RNG / replay.
