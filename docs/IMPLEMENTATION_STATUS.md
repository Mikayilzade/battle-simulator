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

## Completed gate: deterministic scheduler + RNG + replay

Added `domain/battle_scheduler.gd`, `battle_rng.gd`, `battle_state_codec.gd`, `battle_replay_record.gd`, `battle_replay.gd` and `tests/run_replay_tests.gd`. Updated `BattleState` with `first_side_id` and `rng_state`, its copy routine, and state validation. Existing command behavior remains unchanged.

**Scheduler order:** on odd rounds, Blue then Red; on even rounds, Red then Blue, relative to `first_side_id`. Within each side, use authored roster index. Interleave index pairs (`Blue[0], Red[0], Blue[1], Red[1]` for Blue first), skip dead or already activated squads, and use `BattleRules.start_activation`. After all living squads have activated, `BattleRules.finish_round` advances or resolves the round cap. The scheduler derives order from IDs and roster arrays, independent of scene nodes.

**RNG v1:** xorshift32 with unsigned 32-bit state. Normalize seed with `seed & 0xffffffff`; map zero to `0x6d2b79f5`. One sample applies xor shifts 13 left, 17 right, 5 left, masking to 32 bits after each step. The resulting state is also the returned `u32`. `BattleRng.advance` copies canonical state and advances only `rng_state`. Current attacks consume no RNG.

**Replay v1:** `BattleReplayRecord.to_dict()` contains `schema_version`, `replay_version`, `rng_version`, balance ID/version, map ID, seed, initial side ID, initial side/squad/member setup, and an ordered command log. Commands contain only kind, squad/member/target IDs, and movement path cells. The setup excludes action/guard progress. `BattleReplay.run` rebuilds state, validates setup and versions, schedules each activation, applies logged commands, and reports a numbered error on mismatch or illegality. It closes a fully completed final round. `BattleStateCodec.normalized` includes all canonical state fields, including RNG and activation tracking, for value comparison.

Using `C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe`, the commands run for this gate were:

```powershell
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --editor --import --quit
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/run_validation_tests.gd
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/run_command_tests.gd
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/run_replay_tests.gd
```

Final import and all three runners exited 0. Outputs: `Validation tests passed`, `Command transition tests passed`, `Scheduler/RNG/replay tests passed`. Source scan of `domain/` found no Node/SceneTree/Control/Timer/UI class or global random calls.

Next gate: baseline AI + headless batch runner.
