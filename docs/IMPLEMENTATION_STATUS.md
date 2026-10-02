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

## Completed gate: baseline AI + headless batch runner

Added `ai/ai_policy_def.gd`, `ai/default_policy.tres`, `ai/baseline_ai.gd`, `tools/headless_battle.gd`, `tools/batch_simulator.gd`, and `tests/run_ai_tests.gd`. Added authored `data/maps/broken_pass.tres` (9×7, two blocked center cells, two rough flank cells, legal mirrored spawns) and four force presets for the diagnostic matrix. Domain gained a read-only command legality query and a `spawn_swapped` setup/replay field. Corrected occupancy validation so a dead squad's former cell is free, matching movement rules.

AI receives canonical state and the domain's legal command list. For ATTACK it applies the candidate to a copy to score actual HP loss and death. MOVE gets priority when a domain legality check confirms it enables an attack in the same activation; otherwise it must reduce Manhattan distance, with a small exposure penalty. GUARD requires a nearby threat; SET_FRONT requires a threat and at least 3 points of `current HP + armor` improvement; PASS is the fallback. Stable ties use command kind, target IDs, destination y/x, attacker ID and path. Default policy consumes no RNG. All provisional scoring lives in `ai/default_policy.tres`: lethal 7000, attack 6000, enabling move 4000, progress move 3000, guard 2000, set front 1000, damage weight 10, commander damage bonus 1, progress weight 10, exposure penalty 2, front threshold 3.

`HeadlessBattle` creates validated setup, calls the scheduler, lets each side's configured baseline policy choose from legal commands, applies domain transitions, checks every next state, optionally verifies replay, and collects battle metrics. `batch_simulator.gd` writes JSON and prints a concise summary. It accepts `--count`, `--seed-start`, `--output`, `--blue-policy`, `--red-policy` and `--replay-every`. The 200-stratum matrix is 2 maps × 5 Blue presets × 5 Red presets × 2 spawn orientations × 2 first-side orders; presets are Guard+Guard, Striker+Striker, Archer+Archer, Guard+Archer, Striker+Archer. Seeds are paired across mirror and initiative variants. The full run used 50 seeds per stratum, 1 through 50.

Commands run with `C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe`:

```powershell
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --editor --import --quit
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/run_validation_tests.gd
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/run_command_tests.gd
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/run_replay_tests.gd
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/run_ai_tests.gd
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tools/batch_simulator.gd -- --count=200 --seed-start=1 --output=reports/small_batch.json
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tools/batch_simulator.gd -- --count=200 --seed-start=1 --replay-every=1 --output=reports/small_batch_replay_all.json
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tools/batch_simulator.gd -- --count=10000 --seed-start=1 --output=reports/diagnostic_10000.json
```

Final import, four test runners, 200-battle batches and 10,000-battle batch exited 0. The full batch took **485.871 s** (8 min 5.871 s): Blue 4700 wins, Red 4700, draws 600; first side won 5200 of 9400 decisive battles (55.3%); average 8.98 rounds and 29.84 activations; 1400 round-cap outcomes. Open Field: 2500/2500/0 Blue/Red/draw; Broken Pass: 2200/2200/600. There were **0** invalid commands, invariant failures and replay mismatches; 50 sampled full-batch battles and a separate 200-battle sweep covering every stratum passed replay equality. All 10,000 battles terminated by elimination or cap. The first-side advantage and Broken Pass timeout/draw rate are tuning evidence only; balance values were not changed. Since combat currently consumes no RNG, the 50 seeds repeat deterministic outcomes for each fixed stratum. Machine-readable report: `reports/diagnostic_10000.json` (local, ignored by Git).

Next gate: minimal Setup/Battle/Result UI.

## Completed gate: minimal playable Setup / Battle / Result UI

Added `ui/main/main.gd` and `battle_data.gd`, `ui/setup/Setup.tscn` and `setup.gd`, `ui/battle/Battle.tscn`, `battle.gd` and `board_view.gd`, `ui/result/Result.tscn` and `result.gd`, plus `tests/run_ui_smoke.gd`. `Main` switches screens and carries setup choices; `Battle` alone holds the canonical `BattleState`. `UiBattleData` loads shipped definitions and turns selections into a fixed-spawn setup. No Autoload or parallel combat rules were added.

Navigation is Setup → Battle → Result. Setup selects either fixed map and two Guard/Striker/Archer squads per side; autofill chooses Guard + Archer. Blue commands come from `BattleRules.legal_commands` and go through `BattleRules.apply_command`. Red uses `BaselineAi` with the same legal list and scheduler. The board is a 2D top-down 9×7 view with terrain drawing, spawn outlines, Blue circles and Red diamonds, HP bars, reachable cells, targets and hovered routes. Damage preview applies a candidate to a domain copy. The event feed reads transition events and state differences. Presentation timers pace Red steps only. Restart reconstructs the exact setup; Rematch toggles spawn orientation and first side; Edit Forces returns to the retained choices.

Commands run with `C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe`:

```powershell
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --editor --import --quit
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/run_validation_tests.gd
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/run_command_tests.gd
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/run_replay_tests.gd
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/run_ai_tests.gd
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/run_ui_smoke.gd
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tools/batch_simulator.gd -- --count=20 --seed-start=1 --output=reports/ui_gate_small_batch.json
```

The import and all five test runners exited 0. The 20-battle regression exited 0: Blue 14, Red 6, draws 0, timeout 4, sampled replay 1, runtime 1.426 s. A domain source scan found no UI/Node/Timer/global random dependency (ripgrep exit 1 = no match).

Normal visual launch used:

```powershell
Start-Process -FilePath 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64.exe' -ArgumentList @('--editor','--path','.')
Start-Process -FilePath 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64.exe' -ArgumentList @('--path','.')
```

Setup, Battle and Result were inspected in the visible 1280×720 Godot window. Start Battle, a highlighted MOVE and PASS were clicked; the Red AI's movement and attack appeared on the board and in the feed. Repeated PASS actions reached a Red Win Result in round 9; clicking Rematch returned to Battle with the spawn sides swapped and Red acting first. The initial button-grid presentation was replaced with a top-down board after visual review. The UI smoke runner also exercised a complete match plus Restart, Rematch and Edit Forces. Visual limitations: simple vector terrain/tokens and basic panels; no illustrated map cards, dedicated keyboard shortcuts or art/animation polish yet.

Next gate: presentation polish + Windows playtest export.

## Visual rework spike: strategy-map presentation

Replaced the rectangular button grid and permanent right-side debug command column. `ui/battle/board_view.gd` now projects the unchanged 9×7 logical cells into a centered isometric field with shallow tile sides, grassy plain, rocky rough ground and raised blocked rocks. Spawn, reachable, hover, active and attack target marks are temporary translucent world overlays; a hovered MOVE draws its route and arrow. `ui/battle/squad_marker.gd` draws original procedural grouped figures, side banners, role silhouettes (shield/sword/bow), commander pennant, ground shadow and a compact HP strip. No external art assets or combat-rule changes.

`ui/battle/command_panel.gd` provides a short bottom command bar. Attacker/target choices appear in Attack mode; front choice appears only for Formation. `ui/battle/battle.gd` remains the presentation/controller adapter, with a small active-formation panel and collapsible chronicle. `ui/setup/setup.gd` now uses two force-card columns with procedural role emblems (`ui/setup/unit_emblem.gd`) and a live isometric map preview with two map choices. `ui/result/result.gd` presents the final field beside a compact victory/survivor report. Main navigation and all domain, AI, scheduler, replay and balance files are unchanged. `tests/run_ui_smoke.gd` now covers map-card preview updates, all 63 isometric cell hit tests, 1280×720 stage bounds and click/panel paths for MOVE, ATTACK, GUARD, SET_FRONT and PASS.

Background commands run with `C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe`:

```powershell
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --editor --import --quit
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --quit-after 5
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/run_validation_tests.gd
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/run_command_tests.gd
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/run_replay_tests.gd
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/run_ai_tests.gd
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/run_ui_smoke.gd
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tools/batch_simulator.gd -- --count=20 --seed-start=1 --output=reports/visual_spike_small_batch.json
```

Final import, headless main-scene load, all five runners and the 20-battle batch exited 0. Batch results: Blue 14, Red 6, draws 0, timeouts 4, sampled replay checks 1, runtime 1.362 s. An attempted offscreen viewport capture with `--headless` could not produce an image because this Godot configuration uses the dummy renderer (`texture_2d_get: Parameter "t" is null`); the temporary capture script was removed. No visible Godot/GUI window was opened in this pass.

Human visual review is still needed for 1280×720 layout, tile/unit readability, overlap and art direction. After that review, the next gate remains presentation polish and Windows playtest export.

## Visual Style Lab checkpoint

Added an independent Visual Style Lab entered from Setup and exited back to the same setup choices. `ui/main/main.gd` owns the screen transition and a session-only `VisualLabSelection`; neither battle state nor combat rules are changed. `ui/visual_lab/VisualLab.tscn` and `visual_lab.gd` provide Field Styles, Terrain Library, Unit Styles, Combined Preview, and Shortlist / Archive. A procedural `VisualLabPreview` draws a representative ten-terrain stand with Blue and Red Guard/Striker/Archer, selected/reachable/target overlays, and distinct side shapes. It uses no live battle state.

The catalog is data-driven through `VisualVariantDef` Resources in `ui/visual_lab/variants/`: 5 field directions (two overhead, two isometric/2.5D, one faux-3D), 20 terrain variants (ink and relief for each of 10 families), and 9 unit variants (emblem, grouped figures, miniature for each role). IDs such as `FIELD-25D-01`, `TERRAIN-FOREST-25D-01`, and `UNIT-ARCHER-3D-01` are stable and separate from labels. `render_key` selects a procedural drawing treatment; new descriptors can be added without changing Lab navigation. Favorite/archive status is independent of preview selection; archived entries remain selectable. Choices persist while the application is open, not across restarts. Terrain families beyond the two playable map terrains are Lab art samples only.

Background commands run with `C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe`:

```powershell
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --editor --import --quit
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --quit-after 5
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/run_visual_lab_tests.gd
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/run_validation_tests.gd
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/run_command_tests.gd
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/run_replay_tests.gd
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/run_ai_tests.gd
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/run_ui_smoke.gd
& 'C:\Users\User\OneDrive\Desktop\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tools/batch_simulator.gd -- --count=20 --seed-start=1 --output=reports/visual_lab_small_batch.json
```

The final import, headless main-scene load, Lab test, five existing regression runners and 20-battle sample all exited 0. Sample: Blue 14 wins, Red 6, no draws, 4 timeouts, one replay check, 1.508 s. No visible Godot window was opened. Human review is still required for actual screen readability, comparison strength of the five field directions, and which exact IDs should be shortlisted or archived. The Lab does not choose a final style. Side-turn scheduler changes remain a separate mechanics task.
