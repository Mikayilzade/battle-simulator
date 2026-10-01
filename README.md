# Battle Simulator

Standalone Godot 4 / GDScript tactics experiment derived from the Battle Simulator design work in Epohi.

## Status

Bootstrap only. The combat design is frozen for the first implementation experiment in `docs/BATTLE_SIMULATOR_DESIGN.md`.

Fixed first-experiment decisions:
- Godot 4 + GDScript.
- Each squad activates once.
- Its action pool equals its living members.
- Combat/domain rules stay independent of Nodes, UI and animation.
- Deterministic RNG and headless batch simulation are required.
- Balance values remain centralized and reversible.

## Intended structure

- `domain/` — pure combat state/rules/scheduler/replay.
- `data/` — typed Resources and authored `.tres` definitions.
- `ai/` — policies using the same legal commands as players.
- `ui/` — Setup/Battle/Result presentation adapters.
- `tools/` — headless simulation/replay/tuning helpers.
- `tests/` — domain, determinism, invariants, AI and scene smoke tests.
- `docs/` — design contract and implementation checkpoints.

Start implementation in the order and acceptance gates defined in the design document. Do not add battalion/army, Production/Training, networking or Epohi integration during the MVP.
