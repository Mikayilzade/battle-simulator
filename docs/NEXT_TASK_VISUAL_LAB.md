# Next task — build Visual Style Lab

Source direction:
- docs/VISUAL_LAB_IDEAS_2026-10-02.md
- docs/IMPLEMENTATION_STATUS.md
- docs/BATTLE_SIMULATOR_DESIGN.md

## Goal

Create the first usable **Visual Style Lab** inside the existing Godot project so the
user can compare visual directions before more battle-screen polish.

This task is primarily presentation/UI experimentation.

## Preserve

Do not regress or redesign the working combat core:
- schemas/validation
- battle rules
- deterministic scheduler/RNG/replay
- baseline AI
- headless batch runner
- existing playable battle

Do not make the Visual Lab depend on battle-state mutation.

## Required first-pass Lab

Add a way to enter a Visual Lab from the project without replacing the existing battle
flow.

Provide these browseable areas:

1. Field Styles
2. Terrain Library
3. Unit Styles
4. Combined Preview
5. Shortlist / Archive

### Field Styles

Create several clearly different field directions covering at least:
- 2D
- 2.5D
- faux-3D / 3D-look

Aim for real visual contrast, not tiny palette changes.

### Terrain

Create exploratory visual variants for:
- grass/plain
- fields
- forest
- hills
- mountains
- rough
- rocks/blockers
- lake
- sea
- road/path

It is acceptable for the first pass to use a smaller number of variants per terrain
if the architecture supports adding many more later.

### Units

Create several clearly different exploratory variants for:
- Guard
- Striker
- Archer

Cover:
- 2D
- 2.5D
- faux-3D / 3D-look

The long-term target is up to 10 variants per role per mode, but the first pass should
prioritize genuinely different art directions over filling a quota with weak variants.

Every variant needs a stable human-readable ID.

### Combined Preview

Allow mixing field + terrain + unit variants in one representative preview.

Include at least:
- Blue and Red units together;
- normal state;
- selected state;
- reachable overlay;
- target overlay;
- rough/blocked terrain.

### Selection state

Support:
- neutral
- shortlist/favorite
- archive
- selected in preview

Do not delete archived variants.

## Turn flow note

Do **not** change the scheduler in this visual task.

The user currently prefers side turns:
all available Blue squads in any chosen order -> End Turn -> all available Red squads ->
End Turn.

This working direction is documented in VISUAL_LAB_IDEAS_2026-10-02.md and should be
implemented in a separate mechanics task after the Lab direction is established or when
explicitly requested.

## Technical direction

Prefer data-driven visual variant descriptors so more variants can be added without
rewriting the Lab UI.

Possible structure (adapt if a smaller clean approach is better):

- ui/visual_lab/
- visual_lab.gd / VisualLab.tscn
- visual variant Resource definitions
- procedural preview components
- small catalog(s) of field/terrain/unit styles

Use original procedural drawing/simple generated geometry/materials. No copyrighted
commercial assets.

Keep stable IDs separate from display labels.

## Verification

Run in background unless the user explicitly asks for a visible launch:

- Godot headless import
- existing regression runners
- new Lab scene/resource smoke test
- main scene load

Do not run the full 10k battle matrix unless domain/AI logic changes.

## Documentation

Append a concise checkpoint to docs/IMPLEMENTATION_STATUS.md:
- Lab architecture
- variants added
- stable ID scheme
- tests run
- what still requires human visual review

## Git

Work on the existing main branch.
Do not create a new repo/branch/PR.
Commit a coherent Lab package and push main.

Suggested commit:
feat: add visual style lab

## Stop condition

Do not choose a final style on the user's behalf.

The task is complete when there is a useful comparison stand with clearly different
options and stable IDs ready for user review.
